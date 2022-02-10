module DirectUploader
  class Configuration
    def adapter=(adapter_class)
      @adapter_class = adapter_class
    end

    def adapter
      return @adapter_class if @adapter_class.present?
    end
  end
end
