require 'spec_helper'
require 'pushr/daemon'
require 'pushr/daemon/dispatcher'
require 'pushr/daemon/apns'
require 'pushr/daemon/apns_support/connection_apns'
require 'pushr/configuration_apns'
require 'pushr/daemon/message_handler'
describe Pushr::Daemon::Apns do
  let(:config){Pushr::ConfigurationApns.new(app: 'app_name', connections: 1, enabled: true, certificate: 'BEGIN CERTIFICATE',
                                            certificate_password: nil, sandbox: true, skip_check_for_error: true)
}
  let(:apns_configuration){Pushr::Daemon::Apns.new(config)}
  # ==
  # start
  # ==
  describe "#start" do
    let(:version){:apns_tcp}
    let(:dispatcher){double(Pushr::Daemon::Dispatcher)}
    let(:connection_apns_tcp){double(Pushr::Daemon::ApnsSupport::ConnectionApns)}
    let(:message_handler){double(Pushr::Daemon::MessageHandler)}
    before(:each) do
      allow(config).to receive(:version).and_return version
      allow(Pushr::Daemon::Dispatcher).to receive(:get_dispatcher).with(version).and_return dispatcher
      allow(dispatcher).to receive(:new).with(config, 1).and_return connection_apns_tcp
      allow(connection_apns_tcp).to receive(:connect)
      allow(Pushr::Daemon::MessageHandler).to receive(:new).with("pushr:#{config.key}", connection_apns_tcp, config.app, 1).and_return message_handler
      allow(message_handler).to receive(:start)
    end
    it "proxies to Pushr::Daemon::Dispatcher" do
      expect(Pushr::Daemon::Dispatcher).to receive(:get_dispatcher).with(version).and_return dispatcher
      expect(dispatcher).to receive(:new).with(config, 1).and_return connection_apns_tcp
      apns_configuration.start
    end

    it "proxies to MessageHandler" do
      expect(Pushr::Daemon::MessageHandler).to receive(:new).with("pushr:app_name:apns", connection_apns_tcp, config.app, 1)
      apns_configuration.start
    end
  end
end
