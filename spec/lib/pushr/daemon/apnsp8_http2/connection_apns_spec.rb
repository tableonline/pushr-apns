require 'spec_helper'
require 'pushr/configuration_apns'
require 'pushr/daemon/apnsp8_http2/connection_apns'
require 'pushr/daemon'
require 'net-http2'
require 'pushr/message_apns'
require 'pushr/daemon/apnsp8_http2/token'

describe Pushr::Daemon::Apnsp8Http2::ConnectionApns do
  let(:apn_key) { File.read(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'support', 'apn_key.p8')) }
  let(:connection) { Pushr::Daemon::Apnsp8Http2::ConnectionApns.new(config, 1) }

  let(:config) do
    Pushr::ConfigurationApns.new(app: 'app_name', connections: 2, enabled: true, 
                                 version: :apnsp8_http2,
                                 bundle_id: "bundle_id",
                                 team_id: "team_id",
                                 apn_key: apn_key,
                                 apn_key_id: "apn_key_id"
                                )
  end

  let(:net_http2_client){double('NetHttp2::Client').as_null_object}
  before(:each) do
    Pushr::Core.configure do |config|
      config.redis = ConnectionPool.new(size: 1, timeout: 1) { MockRedis.new }
    end

    logger = double('logger')
    allow(logger).to receive(:info)
    allow(logger).to receive(:error)
    allow(logger).to receive(:warn)
    Pushr::Daemon.logger = logger

    allow(NetHttp2::Client).to receive(:new).and_return(net_http2_client)
  end
  let(:message) do
    hsh = { app: 'app_name', device: 'a' * 64,  alert: 'message', badge: 1, sound: '1.aiff', expiry: 24 * 60 * 60,
            attributes_for_device: { key: 'test' }, priority: 10 }
    Pushr::MessageApns.new(hsh)
  end




  # ==
  # write
  # ==
  describe 'sends a message' do
    it 'succesful' do
      expect(connection).to receive(:setup_client)
      expect(connection).to receive(:send_post_request)
      expect(connection).to receive(:close)
      connection.write(message)
    end
  end

  # ==
  # send_post_request
  # =
  describe "#send_post_request" do
    before(:each) do
      allow(connection).to receive(:build_request).and_return request
      allow(connection).to receive(:client).and_return net_http2_client
    end
    let(:request) do
      {
        path: "path_request",
        headers: {},
        body:{}
      }
    end

    it "proxies to #build_request" do
      expect(connection).to receive(:build_request).with(message).and_return request
      expect(connection.client).to receive(:call).with(:post, request[:path], {:body=>{}, :headers=>{}})
      connection.send(:send_post_request, message)
    end
  end

  # ==
  # prepare_body
  # =
  describe "#prepare_body" do
    it "proxies to #prepare_body" do
      payload = connection.send(:prepare_body, message)
      back_json = MultiJson.load(payload)
      expect(back_json).to include("aps")
      expect(back_json["aps"]["alert"]).to eq("message")
      expect(back_json["aps"]["badge"]).to eq(1)
      expect(back_json["aps"]["sound"]).to eq("1.aiff")
      expect(back_json["aps"]["category"]).to be_nil
    end
  end

  # ==
  # build_request
  # =
  describe "#build_request" do
    let(:body) do
      {}
    end

    let(:headers) do
      {}
    end
    before(:each) do
      allow(connection).to receive(:prepare_headers).and_return headers
      allow(connection).to receive(:prepare_body).and_return body
    end
    it "proxies to prepare_headers and prepare_body" do
      expect(connection).to receive(:prepare_headers).with(message)
      expect(connection).to receive(:prepare_body).with(message)
      connection.send(:build_request, message)
    end

    it "returns an hash with requested keys" do
      hash_req =  connection.send(:build_request, message)
      expect(hash_req).to include(:path, :body, :headers)
      expect(hash_req[:path]).to eq("/3/device/#{'a' * 64}")
    end
  end

  # ==
  # prepare_headers
  # =
  describe "#prepare_headers" do
    it "setup header info" do
      info = connection.send(:prepare_headers, message)
      expect(info).to include('content-type', 'apns-expiration', 'apns-topic', 'apns-priority', 'authorization', 'apns-push-type')
      expect(info['content-type']).to eq('application/json')
      expect(info['apns-expiration']).to eq('0')
      expect(info['apns-priority']).to eq('10')
      expect(info['apns-topic']).to eq('bundle_id')
      expect(info['authorization']).to include("bearer")
      expect(info['apns-push-type']).to eq('alert')
    end
  end
end

