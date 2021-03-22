require 'spec_helper'
require 'pushr/configuration_apns'

describe Pushr::ConfigurationApns do

  before(:each) do
    Pushr::Core.configure do |config|
      config.redis = ConnectionPool.new(size: 1, timeout: 1) { MockRedis.new }
    end
  end

  describe 'all' do
    it 'returns all configurations' do
      expect(Pushr::Configuration.all).to eql([])
    end
  end

  describe 'create' do
    it 'should create a configuration' do
      config = Pushr::ConfigurationApns.new(app: 'app_name', connections: 2, enabled: true, certificate: 'BEGIN CERTIFICATE',
                                            certificate_password: nil, sandbox: true, skip_check_for_error: true, version: :apns_tcp)
      expect(config.key).to eql('app_name:apns')
    end
  end

  describe 'save' do
    let(:version){:apns_tcp}
    let(:config) do
      Pushr::ConfigurationApns.new(app: 'app_name', connections: 2, enabled: true, certificate: 'BEGIN CERTIFICATE',
                                   certificate_password: nil, sandbox: true, skip_check_for_error: true, version: version)
    end

    context "version is apnsp8_http2" do
      let(:version){:apnsp8_http2}
      context "all requested attr are present" do
        let(:config) do
          Pushr::ConfigurationApns.new(app: 'app_name', connections: 2, enabled: true,bundle_id: 'bundle_id', apn_key: 'BEGIN PRIVATE KEY', team_id: "team_id", apn_key_id: "apn_key_id", 
                                       sandbox: true, skip_check_for_error: true, version: version)
        end
        it { expect{config.save}.to change{Pushr::Configuration.all.count}.by(1)}

      end
      context "bundle_id is missing" do
        let(:config) do
          Pushr::ConfigurationApns.new(app: 'app_name', connections: 2, enabled: true, apn_key: 'BEGIN PRIVATE KEY',
                                       sandbox: true, skip_check_for_error: true, version: version)
        end
        it { expect{config.save}.to change{Pushr::Configuration.all.count}.by(0)}
      end

       context "apn_key is missing" do
        let(:config) do
          Pushr::ConfigurationApns.new(app: 'app_name', connections: 2, enabled: true, bundle_id: 'bundle_id',
                                       sandbox: true, skip_check_for_error: true, version: version)
        end
        it { expect{config.save}.to change{Pushr::Configuration.all.count}.by(0)}
      end

       context "team_id is missing" do
         let(:config) do
           Pushr::ConfigurationApns.new(app: 'app_name', connections: 2, enabled: true, bundle_id: 'bundle_id', apn_key: 'BEGIN PRIVATE KEY',
                                        sandbox: true, skip_check_for_error: true, version: version)
         end
         it { expect{config.save}.to change{Pushr::Configuration.all.count}.by(0)}
       end

       context "apn_key_id is missing" do
         let(:config) do
           Pushr::ConfigurationApns.new(app: 'app_name', connections: 2, enabled: true, bundle_id: 'bundle_id', apn_key: 'BEGIN PRIVATE KEY', team_id: "team_id",
                                        sandbox: true, skip_check_for_error: true, version: version)
         end
         it { expect{config.save}.to change{Pushr::Configuration.all.count}.by(0)}
       end

    end
    context "version is apns_tcp" do 
      let(:version){:apns_tcp}
      it { expect{config.save}.to change{Pushr::Configuration.all.count}.by(1)}
      it 'should save a configuration' do
        config.save
        expect(Pushr::Configuration.all.count).to eql(1)
        expect(Pushr::Configuration.all[0].class).to eql(Pushr::ConfigurationApns)
      end
    end
  end
end
