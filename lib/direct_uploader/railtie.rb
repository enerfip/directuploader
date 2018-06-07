require "direct_uploader/view_helpers"

module DirectUploader
  class Railtie < Rails::Railtie
    initializer "direct_uploader.view_helpers" do
      ActionView::Base.send :include, ViewHelpers
    end
  end
end
