module DirectUploader
  module ViewHelpers
    def directupload_field_for(f, field, options = {})
      object = f.object.to_model
      data = { 'form-data' => object.presigned_post[:fields],
               'url'       => object.presigned_post[:url],
               'host'      => URI.parse(object.presigned_post[:url]).host
      }
      if object.direct_uploader_field_options[field][:max_file_size].present?
        data['max_file_size'] = object.direct_uploader_field_options[field][:max_file_size]
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
