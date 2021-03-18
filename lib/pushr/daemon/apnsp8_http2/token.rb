require 'jwt'
module Pushr
  module Daemon
    module Apnsp8Http2
      TOKEN_TTL = 30 * 60
      attr_reader :configuration
      attr_accessor :cached_token, :cached_token_at
      class Token
        def initialize(configuration)
          @configuration = configuration
          @cached_token = nil
        end

        def token
          if self.cached_token && !expired_token?
            self.cached_token
          else
            new_token
          end
        end

        private

        def new_token
          self.cached_token_at = Time.now
          ec_key = OpenSSL::PKey::EC.new(self.configuration.apn_key)
          self.cached_token = JWT.encode(
            {
              iss: self.configuration.team_id,
              iat: Time.now.to_i
            },
            ec_key,
            'ES256',
            {
              alg: 'ES256',
              kid: self.configuration.apn_key_id
            }
          )
        end

        def expired_token?
          Time.now - self.cached_token_at >= TOKEN_TTL
        end
      end
    end
  end
end

