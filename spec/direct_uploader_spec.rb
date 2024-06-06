require "spec_helper"
require "active_model"
require "direct_uploader"
require "direct_uploader/view_helpers"
require 'active_support/time'

RSpec.describe DirectUploader do
  include DirectUploader::ViewHelpers
  class DummyModel
    include ActiveModel::Model
    def self.before_save(meth = nil, &block)
    end

    include DirectUploader::Model

    attr_accessor :document, :document2, :document3, :custom_size

    direct_uploader :document, file_type: %w{jpeg jpg gif png}, max_file_size: 10_000_00
    direct_uploader :document2
    direct_uploader :document3, file_type: %w{jpeg jpg gif png}, max_file_size: ->(doc) { doc.custom_size }
  end

  class DummyModelChild < DummyModel
    direct_uploader :document, file_type: %w{zip}
  end

  context "configuration" do
    it "adapter can be configured with any class" do
      DirectUploader.configure do |config|
        config.adapter = Object
      end

      expect(DirectUploader.configuration.adapter).to eq(Object)
    end

    it "default adapter is S3" do
      # Reset configuration as it is a class variable
      DirectUploader.configure do |config|
        config.adapter = nil
      end

      expect(DirectUploader.configuration.adapter).to eq(DirectUploader::Adapter::S3)
    end

    it "fixture file path can be configured" do
      DirectUploader.configure do |config|
        config.fixture_path = 'tmp/pixel.png'
      end

      expect(DirectUploader.configuration.fixture_path).to eq('tmp/pixel.png')
    end
  end

  it "has a version number" do
    expect(DirectUploader::VERSION).not_to be nil
  end

  it "allows to retreive options" do
    expect(DummyModel.new.direct_uploader_field_options[:document]).to eq file_type: %w{jpeg jpg gif png}, max_file_size: 10_000_00
    expect(DummyModel.new.direct_uploader_field_options[:document2]).to eq({})
    expect(DummyModelChild.new.direct_uploader_field_options[:document]).to eq file_type: %w{zip}
  end

  it "adds validator for file type" do
    validator = DummyModel._validators[:document].first
    expect(validator).to be_kind_of ActiveModel::Validations::FormatValidator
    expect(validator.options).to eq with: /\.(jpeg|jpg|gif|png)\z/, allow_nil: true
  end

  it "does not add validator if no options specified" do
    validators = DummyModel._validators[:document2]
    expect(validators).to be_empty
  end

  describe "directupload_field_for" do
    let(:object) { DummyModel.new }
    let(:f) { double(object: object) }

    it "generates a field with some relevant options" do
      allow(object).to receive(:document).and_return nil
      allow(object).to receive(:document_presigned_post).and_return fields: "document", url: "https://upload.com/url"
      data = {
        "form-data" => "document",
        "url" => "https://upload.com/url",
        "host" => "upload.com",
        "max_file_size" => 10_000_00,
        "file_type" => "jpeg|jpg|gif|png"
      }
      allow(object).to receive(:document).and_return nil
      expect(f).to receive(:input).with(:document, as: :file, input_html: { class: "directUpload", data: data }, hint: uploader_hint(f.object, "document", {}))
      directupload_field_for(f, :document)
    end

    it "allows dynamic file size validation" do
      allow(object).to receive(:document3).and_return nil
      object.custom_size = 5000_00
      allow(object).to receive(:document3_presigned_post).and_return fields: "document3", url: "https://upload.com/url"
      data = {
        "form-data" => "document3",
        "url" => "https://upload.com/url",
        "host" => "upload.com",
        "max_file_size" => 5000_00,
        "file_type" => "jpeg|jpg|gif|png"
      }
      allow(object).to receive(:document3).and_return nil
      expect(f).to receive(:input).with(:document3, as: :file, input_html: { class: "directUpload", data: data }, hint: uploader_hint(f.object, "document3", {}))
      directupload_field_for(f, :document3)
    end

  end
end
