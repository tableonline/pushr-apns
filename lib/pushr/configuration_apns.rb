module Pushr
  class ConfigurationApns < Pushr::Configuration

    APNS_CONNECTION_VERSION = [:apns_tcp, :apnsp8_http2]
    attr_reader :certificate
    attr_accessor :certificate_password, :sandbox, :skip_check_for_error, :version

    #apnsp8_http2
    attr_accessor :bundle_id, :team_id, :apn_key, :apn_key_id

    validates :version, presence: true, inclusion: { in: APNS_CONNECTION_VERSION}
    validates :certificate, presence: true, if: :apns_tcp?
    validates :sandbox, inclusion: { in: [true, false] }
    validates :skip_check_for_error, inclusion: { in: [true, false] }, allow_blank: true

    #apnsp8_http2 configuration
    validates :apn_key, :apn_key_id, :bundle_id, :team_id, presence: true, if: :apnsp8_http2?

    def name
      :apns
    end

    def certificate=(value)
      if /BEGIN CERTIFICATE/.match(value)
        @certificate = value
      else
        # assume it's the path to the certificate and try to read it:
        @certificate = read_file(value) if value 
      end
    end

    def apn_key=(value)
      if /BEGIN PRIVATE KEY/.match(value)
        @apn_key = value
      else
        # assume it's the path to the apn_key and try to read it:
        @apn_key = read_file(value) if value
      end
    end

    def to_hash
      { type: self.class.to_s, app: app, enabled: enabled, connections: connections, certificate: certificate,
        certificate_password: certificate_password, sandbox: sandbox, skip_check_for_error: skip_check_for_error, version: version, bundle_id: bundle_id, team_id: team_id, apn_key: apn_key, apn_key_id: apn_key_id }
    end

    def apns_tcp?
      :apns_tcp == version
    end

    def apnsp8_http2?
      :apnsp8_http2 == version
    end


    private

    # if filename is something wacky, this will break and raise an exception - that's OK
    def read_file(filename)
      File.read(build_filename(filename))
    end

    def build_filename(filename)
      if Pathname.new(filename).absolute?
        filename
      elsif Pushr::Core.configuration_file
        File.join(File.dirname(Pushr::Core.configuration_file), filename)
      else
        File.join(Dir.pwd, filename)
      end
    end
  end
end
