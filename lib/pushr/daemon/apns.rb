module Pushr
  module Daemon
    class Apns
      attr_accessor :configuration, :handlers

      def initialize(options)
        @configuration = options
        @handlers = []
      end

      def start
        dispatcher = Dispatcher.get_dispatcher(self.configuration.version)
        configuration.connections.times do |i|
          connection = dispatcher.new(self.configuration, i + 1)
          connection.connect

          handler = MessageHandler.new("pushr:#{self.configuration.key}", connection, self.configuration.app, i + 1)
          handler.start
          @handlers << handler
        end
      end

      def stop
        @handlers.map(&:stop)
      end
    end
  end
end
