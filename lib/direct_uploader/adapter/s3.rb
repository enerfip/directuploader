module DirectUploader
  module Adapter
    class S3
      def presigned_post(hsh)
        start_path = File.dirname(hsh[:key])
        {
          url: s3_endpoint,
          fields: s3_connection.post_object_hidden_fields(hsh.stringify_keys.except("expires_in").merge "policy" => {
            "conditions" => [{"bucket" => s3_bucket.key}, hsh.stringify_keys.except("key", "expires_in"), ["starts-with", "$key", start_path]],
            "expiration" => (Time.zone.now + hsh.fetch(:expires_in) { 5.minutes }).utc.iso8601
          })
        }
      end

      def presigned_get(file, hsh)
        s3_bucket.files.new(key: file).url(Time.zone.now + hsh.delete(:expires_in) { 1.minute })
      end

      def put_object(key, file)
        s3_bucket.files.create(key: key, body: file)
      end

      def notify_new_object(key, file)
        # noop, this is used for filesystem adapter
      end

      private

      def s3_connection
        @s3_connection ||= DirectUploader.configuration.s3_connection || S3_CONNECTION
      end

      def s3_bucket
        @s3_bucket ||= DirectUploader.configuration.s3_bucket || S3_PRIVATE_BUCKET
      end

      def s3_endpoint
        @s3_endpoint ||= DirectUploader.configuration.s3_endpoint || "https://#{s3_private_bucket.key}.s3.#{s3_connection.region}.amazonaws.com"
      end
    end
  end
end
