require 'net-http2'
require 'pushr/daemon/apnsp8_http2/token'
module Pushr
  module Daemon
    module Apnsp8Http2
      class ConnectionApns
        attr_reader :configuration, :token_provider, :name, :host, :post
        attr_accessor :last_write, :client
        DEFAULT_TIMEOUT = 60
        def initialize(configuration, i=nil)

          @configuration = configuration
          if i
            # Apns push connection
            @name = "#{@configuration.app}: ConnectionApns #{i}"
            @host = "api.#{configuration.sandbox ? 'sandbox.' : ''}push.apple.com"
            #@port = 2197
          else
            @name = "#{@configuration.app}: FeedbackReceiver"
            @host = "feedback.#{configuration.sandbox ? 'sandbox.' : ''}push.apple.com"
            @port = 2196
          end

          @token_provider = Token.new(configuration)
        end


        def setup_client
          self.client = NetHttp2::Client.new("https://#{self.host}", connect_timeout: DEFAULT_TIMEOUT) 
          self.client.on(:error) do |error|
            log_error(error)
          end
        end


        def reconnect
        end

        def connect
        end

        def close
          self.client.close
        end

        def write(data)
          retry_count = 0
          begin
            setup_client
            send_post_request(data)
            close
          rescue Errno::ECONNRESET, Errno::ETIMEDOUT, SocketError => error
            close
            retry_count += 1
            if retry_count == 1
              Pushr::Daemon.logger.error("[#{self.name}] Lost connection (#{error.class.name}), reconnecting...")
            end
            if retry_count <= 3
              sleep 1
              retry
            else
              raise ConnectionError, "#{self.name} tried #{retry_count - 1} times to reconnect but failed (#{error.class.name})."            
            end
          end
        end


        private

        def log_error(e)
          if e.is_a?(Exception)
            Pushr::Daemon.logger.error(e)
          else
            Pushr::Daemon.logger.error("[#{self.name}] Error received, #{e}")
          end
        end
        
        protected

        def send_post_request(notification)
          request = build_request(notification)

          self.client.call(:post, request[:path],
                       body:    request[:body],
                       headers: request[:headers]
                      )
        end

        def build_request(notification)
          {
            path:    "/3/device/#{notification.device}",
            headers: prepare_headers(notification),
            body:    prepare_body(notification)
          }
        end

        def prepare_body(notification)
          #hash = notification.as_json
          #JSON.dump(hash).force_encoding(Encoding::BINARY)
          notification.payload
        end

        def prepare_headers(notification)
          jwt_token = self.token_provider.token

          headers = {}

          headers['content-type'] = 'application/json'
          headers['apns-expiration'] = '0'
          headers['apns-priority'] = notification.priority.to_s
          headers['apns-topic'] = self.configuration.bundle_id
          headers['authorization'] = "bearer #{jwt_token}"
          headers['apns-push-type'] = notification.alert ?  'alert' : 'background' 

          headers
        end
      end
    end
  end
end


