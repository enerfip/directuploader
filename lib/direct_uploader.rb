require "direct_uploader/version"
require "direct_uploader/adapter/file_system"
require "direct_uploader/adapter/s3"
require "direct_uploader/configuration"
require "direct_uploader/model"
require "direct_uploader/railtie" if defined?(Rails)

module DirectUploader
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
