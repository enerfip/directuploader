module DirectUploader
  module Adapter
    class S3
      def presigned_post(hsh)
        start_path = File.dirname(hsh[:key])
        {
          url:    "https://#{S3_PRIVATE_BUCKET.key}.s3.#{S3_CONNECTION.region}.amazonaws.com",
          fields: S3_CONNECTION.post_object_hidden_fields(hsh.stringify_keys.except("expires_in").merge "policy" => {
            "conditions" => [{"bucket" => S3_PRIVATE_BUCKET.key}, hsh.stringify_keys.except("key", "expires_in"), ["starts-with", "$key", start_path]],
            "expiration" => (Time.zone.now + hsh.fetch(:expires_in) { 5.minutes }).utc.iso8601
          })
        }
      end

      def presigned_get(file, hsh)
        S3_PRIVATE_BUCKET.files.new(key: file).url(Time.zone.now + hsh.delete(:expires_in) { 1.minute })
      end

      def put_object(key, file)
        S3_PRIVATE_BUCKET.files.create(key: key, body: file)
      end

      def notify_new_object(key, file)
        # noop, this is used for filesystem adapter
      end
    end
  end
end
