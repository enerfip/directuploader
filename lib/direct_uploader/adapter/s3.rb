module DirectUploader
  module Adapter
    class S3
      ADAPTER_S3_BUCKET = DirectUploader.configuration.s3_private_bucket || S3_PRIVATE_BUCKET
      ADAPTER_S3_CONNECTION = DirectUploader.configuration.s3_connection || S3_CONNECTION
      ADAPTER_S3_ENDPOINT = DirectUploader.configuration.s3_endpoint || "https://#{ADAPTER_S3_BUCKET.key}.s3.#{ADAPTER_S3_CONNECTION.region}.amazonaws.com"

      def presigned_post(hsh)
        start_path = File.dirname(hsh[:key])
        {
          url: ADAPTER_S3_ENDPOINT,
          fields: ADAPTER_S3_CONNECTION.post_object_hidden_fields(hsh.stringify_keys.except("expires_in").merge "policy" => {
            "conditions" => [{"bucket" => ADAPTER_S3_BUCKET.key}, hsh.stringify_keys.except("key", "expires_in"), ["starts-with", "$key", start_path]],
            "expiration" => (Time.zone.now + hsh.fetch(:expires_in) { 5.minutes }).utc.iso8601
          })
        }
      end

      def presigned_get(file, hsh)
        ADAPTER_S3_BUCKET.files.new(key: file).url(Time.zone.now + hsh.delete(:expires_in) { 1.minute })
      end

      def put_object(key, file)
        ADAPTER_S3_BUCKET.files.create(key: key, body: file)
      end

      def notify_new_object(key, file)
        # noop, this is used for filesystem adapter
      end
    end
  end
end
