require "aws-sdk-core"
require "active_support/core_ext/array"

module S3AssetSync

  class DirectoryDiff

    attr_reader :bucket,
                :asset_prefix,
                :rails_asset_path,
                :rails_public_path,
                :client

    def initialize
      @client = Aws::S3::Client.new
      @bucket = S3AssetSync.config.s3_bucket
      @asset_prefix = S3AssetSync.config.asset_prefix.gsub('/','')
      @rails_public_path = S3AssetSync.config.rails_public_path
      @rails_asset_path = File.join(rails_public_path, asset_prefix)
    end

    def files_to_sync
      path = File.join(self.rails_asset_path, '**', '*')

      Dir.glob(path).select  do |f|
        File.file?(f) && !(f =~ S3AssetSync::SPROCKETS_MANIFEST)
      end.map do |f|
        f.gsub(self.rails_asset_path, self.asset_prefix)
      end
    end

    def files_in_bucket
      keys_remain = true
      continuation_token = nil
      file_list = []

      while(keys_remain) do
        params = {
          bucket: self.bucket,
          max_keys: 500
        }

        if continuation_token
          params.merge!(continuation_token: continuation_token)
        end

        response = client.list_objects_v2(params)
        unless response.contents.empty?
          response.contents.each do |entry|
            file_list << entry.key
          end
        end

        continuation_token = response.next_continuation_token
        keys_remain = response.is_truncated
      end

      file_list
    end

    def difference
      local_files = files_to_sync
      remote_files = files_in_bucket
      remote_differences = remote_files - local_files
      remote_differences
    end

    def clean_differences
      difference.in_groups_of(500).each do |group|
        params = {
          bucket: self.bucket,
          delete: {
            objects: group.compact.map {|item| {key: item} }
          }
        }
        self.client.delete_objects(params)
        puts "DELETED: #{params[:delete][:objects]}"
      end
    end

    def self.clean_differences
      new.clean_differences
    end

  end

end
