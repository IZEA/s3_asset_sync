require 'celluloid/current'
require 'celluloid/io'
require 'celluloid/autostart'

require "aws-sdk-core"
require 'mime/types/columnar'
module S3AssetSync
  module Actors
    class S3Upload
      include Celluloid
      include Celluloid::IO

      attr_reader :client, :bucket

      def initialize
        @client = Aws::S3::Client.new#(region: S3AssetSync.config.aws_region)
        @bucket = S3AssetSync.config.s3_bucket
      end

      def perform(file_info, signal)
        file_path = file_info[:file_path]
        base_path = file_info[:base_path]
        prefix    = file_info[:prefix]

        started = Time.now

        key = file_path.gsub(base_path, prefix)

        content_type = content_type_from_key(key)

        file = {
          acl: "public-read",
          bucket: self.bucket,
          body: File.open(file_path),
          key: key,
          content_type: content_type
        }

        # ported from rumblelabs/asset_sync repository
        one_year = 31_557_600
        if /-[0-9a-fA-F]{32,64}$/.match(File.basename(key, File.extname(key)))
          file.merge!(
            cache_control: "public, max-age=#{one_year}",
            expires: CGI.rfc1123_date(Time.now + one_year)
          )
        end

        if File.extname(file_path) == ".gz"
          file.merge!(
            content_encoding: "gzip"
          )
        end

        @client.put_object(file)

        done = Time.now
        status = {file: file_path, started: started, done: done, elapsed: started - done, thread: Thread.current.object_id.to_s(16)}
        signal.call(status)
        status
      end

      private

      def content_type_from_key(key)
        ext = File.extname(key)
        mime = MIME::Types.type_for(ext).first

        if mime
          mime.content_type
        else
          ""
        end
      end

    end
  end
end
