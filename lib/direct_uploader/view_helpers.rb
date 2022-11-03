module DirectUploader
  module ViewHelpers
    def directupload_field_for(f, field, options = {})
      object = f.object.to_model
      post_options = { expires_in: options.fetch(:expires_in) { 5.minutes } }
      presigned_post = object.public_send("#{field}_presigned_post", post_options)
      data = { 'form-data' => presigned_post[:fields],
               'url'       => presigned_post[:url],
               'host'      => URI.parse(presigned_post[:url]).host
      }
      if object.direct_uploader_field_options[field][:max_file_size].present?
        validation = object.direct_uploader_field_options[field][:max_file_size]
        if validation.kind_of? Proc
          data['max_file_size'] = object.direct_uploader_field_options[field][:max_file_size].call(object)
        else
          data['max_file_size'] = object.direct_uploader_field_options[field][:max_file_size]
        end
      end

      if object.direct_uploader_field_options[field][:file_type].present?
        data['file_type'] = Array(object.direct_uploader_field_options[field][:file_type]).join("|")
      end

      if options.has_key?(:autosubmit) && options[:autosubmit]
        data['autosubmit'] = "1"
      end
      f.input field.to_sym,
        options.merge(
          as: :file,
          input_html: {
            class: "directUpload",
            data: data
          },
          hint: uploader_hint(object, field, options)
      )
    end

    def uploader_hint(object, field, options)
      ActiveSupport::SafeBuffer.new([options[:hint],
       if object.public_send(field).present? && options[:allow_delete]
         link_to("\n#{I18n.t("direct_uploader.delete_button")}" , options[:path], method: :post, remote: true, id: "delete_picture")
      end
      ].join)
    end
  end
end
