module DirectUploader
  module Adapter
    class FileSystem
      def presigned_post(hsh)
        Hashie::Mash.new(url: "http://localhost/testurl", fields: {})
      end

      def presigned_get(file, hsh)
        ["/", "uploads/", file].join
      end

      def put_object(key, file)
        key = key
          .sub("${filename}", Pathname.new(file).basename.to_s)
          .sub(/\A\//,'')
        path = Rails.root.join("public", "uploads", key)
        FileUtils.mkdir_p(Pathname.new(path).dirname)
        FileUtils.cp(file, path)
      end

      def notify_new_object(key, file)
        fixture_path = DirectUploader.configuration.fixture_path
        base_file = File.new(fixture_path)

        target_file = Rails.root.join("tmp", Pathname.new(file).basename.to_s)
        FileUtils.cp(base_file, target_file)
        put_object(key, target_file)
        FileUtils.rm(target_file)
      end
    end
  end
end
