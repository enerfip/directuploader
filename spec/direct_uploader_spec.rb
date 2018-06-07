require "spec_helper"
require "active_model"
require "direct_uploader/view_helpers"

RSpec.describe DirectUploader do
  include DirectUploader::ViewHelpers
  class DummyModel
    include ActiveModel::Model
    def self.before_save(meth = nil, &block)
    end

    include DirectUploader::Model

    attr_accessor :document, :document2
    direct_uploader :document, file_type: %w{jpeg jpg gif png}, max_file_size: 10_000_00
    direct_uploader :document2
  end

  it "has a version number" do
    expect(DirectUploader::VERSION).not_to be nil
  end

  it "allows to retreive options" do
    expect(DummyModel.new.direct_uploader_field_options[:document]).to eq file_type: %w{jpeg jpg gif png}, max_file_size: 10_000_00
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
      allow(object).to receive(:presigned_post).and_return fields: "some_field", url: "https://upload.com/url"
      data = {
        "form-data" => "some_field",
        "url" => "https://upload.com/url",
        "host" => "upload.com",
        "max_file_size" => 10_000_00,
        "file_type" => "jpeg|jpg|gif|png"
      }
      allow(object).to receive(:some_field).and_return nil
      expect(f).to receive(:input).with(:document, as: :file, input_html: { class: "directUpload", data: data }, hint: uploader_hint(f.object, "some_field", {}))
      directupload_field_for(f, :document)
    end
  end
end
