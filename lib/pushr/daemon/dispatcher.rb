require 'pushr/daemon/apns_support/connection_apns'
require 'pushr/daemon/apnsp8_http2/connection_apns'
module Pushr
  module Daemon
    class NotImplementedError < StandardError; end
    class Dispatcher
      DISPATCHERS = {
        apns_tcp: ApnsSupport::ConnectionApns,
        apnsp8_http2: Pushr::Daemon::Apnsp8Http2::ConnectionApns 
      }

      attr_reader :dispatcher_version, :configuration
      def self.get_dispatcher(version)
        new(version).send(:get_dispatcher)
      end


      private
      def initialize(version)
        @dispatcher_version = version
      end

      def raise_not_implemented_error
        raise NotImplementedError, "no dispatcher class found for #{@dispatcher_version} not implemented."
      end

      def get_dispatcher
        DISPATCHERS[self.dispatcher_version] || raise_not_implemented_error
      end
    end
  end
end
