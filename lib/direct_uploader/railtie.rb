require "direct_uploader/view_helpers"

module DirectUploader
  class Railtie < Rails::Railtie
    initializer "direct_uploader.view_helpers" do
      ActionView::Base.send :include, ViewHelpers
      Rails.configuration.define_singleton_method(:direct_uploader_adapter) { Rails.env.test? ? DirectUploader::Adapter::FileSystem : DirectUploader::Adapter::S3 }
    end
  end
end
