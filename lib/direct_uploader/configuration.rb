module DirectUploader
  class Configuration
    def adapter=(adapter_class)
      @adapter_class = adapter_class
    end

    def adapter
      @adapter_class || DirectUploader::Adapter::S3
    end

    attr_accessor :fixture_path
  end
end
