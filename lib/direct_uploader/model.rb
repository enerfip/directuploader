require "active_support/concern"

module DirectUploader
  module Model
    extend ActiveSupport::Concern

    included do
      before_save :save_direct_uploads
      class_attribute :direct_uploader_fields
      class_attribute :direct_uploader_field_options
      attr_writer :direct_uploader_adapter

      delegate :direct_uploader_field_options, to: :class
    end

    module ClassMethods
      # Note class_attribute works fine with immutable objects like String, but not with mutables like Hash
      # The trick is to use the inherited method in the parent class to clone the attribute in subclass
      # https://stackoverflow.com/questions/28041368/proper-way-to-use-class-attribute-with-hash
      def inherited(child_class)
        super
        child_class.direct_uploader_fields = self.direct_uploader_fields.clone
        child_class.direct_uploader_field_options = self.direct_uploader_field_options.clone
      end

      def direct_uploader(field, options = {})
        self.direct_uploader_fields ||= []
        self.direct_uploader_fields << field unless self.direct_uploader_fields.include?(field)
        self.direct_uploader_field_options ||= {}
        self.direct_uploader_field_options[field] = options
        if self.direct_uploader_field_options[field][:file_type].present?
          validates field, format: { with: /\.(#{Array(direct_uploader_field_options[field][:file_type]).join("|")})\z/}, allow_nil: true
        end

        #TODO: add validations for max_file_size, using AWS::S3 policy

        define_method("#{field}_presigned_post") do |opts = {}|
          if !instance_variable_defined?("@#{field}_s3_direct_post")
            instance_variable_set("@#{field}_s3_direct_post", direct_uploader_adapter.presigned_post(opts.reverse_merge(key: public_send("#{field}_upload_key_for_presigned"), success_action_status: '201')))
          end
          instance_variable_get("@#{field}_s3_direct_post")
        end

        define_method("#{field}_url") do |opts = {}|
          if public_send(field).present?
            if !instance_variable_defined?("@#{field}_document_url")
              instance_variable_set("@#{field}_document_url", direct_uploader_adapter.presigned_get(public_send("#{field}_download_path"), {expires_in: 60.minutes}.merge(opts)))
            end
            instance_variable_get("@#{field}_document_url")
          end
        end

        if !method_defined? "#{field}_filename"
          define_method("#{field}_filename") { nil }
        end

        if !method_defined? "#{field}_upload_filename"
          define_method("#{field}_upload_filename") { nil }
        end

        define_method("#{field}_download_path") do
          raise "No #{field} file was downloaded for #{self.class.name} #{self.id}" unless public_send(field).present?
          "#{upload_path}/#{public_send(field)}"
        end

        define_method("#{field}_upload_key_for_presigned") do
          filename = public_send("#{field}_upload_filename") || public_send("#{field}_filename") || "${filename}"
          "#{upload_path}/#{filename}"
        end

        define_method("#{field}_upload_key") do |file|
          filename = public_send("#{field}_filename") || default_upload_key(file)
          "#{upload_path}/#{filename}"
        end

        define_method("default_upload_key") do |file|
          pathname = Pathname.new(file)
          [pathname.basename(".*").to_s.parameterize, pathname.extname].join
        end

        define_method(field) do
          read_attribute(field).try(:sub, upload_path.to_s + "/", "")
        end

        define_method("#{field}_file=") do |file|
          instance_variable_set("@#{field}_file", file)
        end

        define_method("#{field}_file") do
          instance_variable_get("@#{field}_file")
        end

        define_method("#{field}=") do |file|
          if file.respond_to? :read
            send("#{field}_file=", file)
            filename = public_send("#{field}_filename") || default_basename(file)
            write_attribute(field, filename)
          else
            send("#{field}_file=", nil)
            write_attribute(field, default_basename(file)) if file.present?
          end
        end

        define_method("default_basename") do |file|
          if file.respond_to? :base_uri
            Pathname.new(file.base_uri.path).basename
          else
            Pathname.new(file).basename
          end
        end
      end
    end

    def save_direct_uploads
      self.direct_uploader_fields.each do |field|
        string = public_send(field)
        file = public_send("#{field}_file")

        if file.present?
          key = public_send "#{field}_upload_key", file
          download_key = public_send "#{field}_download_path"
          direct_uploader_adapter.put_object(key, file)
          write_attribute(field, download_key)
          public_send("#{field}_file=", nil)
        else
          if string.present?
            key = public_send "#{field}_upload_key", string
            direct_uploader_adapter.notify_new_object(key, string) if string.present?
          end
          write_attribute(field, string)
        end
      end
    end

    def direct_uploader_adapter
      @direct_uploader_adapter ||= DirectUploader.configuration.adapter.new
    end
  end
end
