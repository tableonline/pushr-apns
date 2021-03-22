require 'spec_helper'
require 'pushr/daemon'
require 'pushr/daemon/dispatcher'
require 'pushr/configuration_apns'
require 'pushr/daemon/apns_support/connection_apns'
require 'pushr/daemon/apnsp8_http2/connection_apns'

describe Pushr::Daemon::Dispatcher do
  let(:version){:apns_tcp}
  let(:dispatcher){Pushr::Daemon::Dispatcher.new(version)}

  # ==
  # =self.get_dispatcher
  # ==
  describe "#self.get_dispatcher" do

    it "proxies to get_dispatcher_instance" do
      expect(Pushr::Daemon::Dispatcher).to receive(:new).with(version).and_call_original
      expect_any_instance_of(Pushr::Daemon::Dispatcher).to receive(:send).with(:get_dispatcher)
      Pushr::Daemon::Dispatcher.get_dispatcher(version)
    end
  end

  # ==
  # =get_dispatcher
  # ==
  describe "#get_dispatcher" do
    subject(:get_dispatcher){dispatcher.send(:get_dispatcher)}

    context "dispatcher_version is known" do
      context "version apns_tcp" do
        let(:version){:apns_tcp}

        it "does not proxy to #raise_not_implemented_error" do
          expect_any_instance_of(Pushr::Daemon::Dispatcher).not_to receive(:raise_not_implemented_error)
          get_dispatcher
        end

        it{expect(get_dispatcher).to eq(Pushr::Daemon::ApnsSupport::ConnectionApns)}
      end

      context "version apnsp8_http2" do
        let(:version){:apnsp8_http2}
        it "does not proxy to #raise_not_implemented_error" do
          expect_any_instance_of(Pushr::Daemon::Dispatcher).not_to receive(:raise_not_implemented_error)
          get_dispatcher
        end
        it{expect(get_dispatcher).to eq(Pushr::Daemon::Apnsp8Http2::ConnectionApns)}

      end

    end

    context "dispatcher_version is unknown" do
      let(:version){:apnsp8_unknown}
         it "proxies to #raise_not_implemented_error" do
          expect_any_instance_of(Pushr::Daemon::Dispatcher).to receive(:raise_not_implemented_error)
          get_dispatcher
        end
    end
  end
end
