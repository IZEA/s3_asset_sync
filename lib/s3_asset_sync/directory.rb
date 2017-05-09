require "colorize"
require "celluloid/current"

Celluloid.boot

require "celluloid/autostart"
require "s3_asset_sync/actors/s3_upload"

module S3AssetSync
  class Directory

    attr_reader :rails_public_path, :rails_asset_path,
                :asset_prefix, :gzip_compression

    def initialize
      @rails_public_path = S3AssetSync.config.rails_public_path
      @asset_prefix = S3AssetSync.config.asset_prefix.gsub('/','')
      @rails_asset_path = File.join(self.rails_public_path, self.asset_prefix)
    end

    def files_to_sync
      path = File.join(self.rails_asset_path, '**', '*')
      Dir.glob(path).select  do |f|
        File.file?(f) && !(f =~ S3AssetSync::SPROCKETS_MANIFEST)
      end
    end

    def sync
      results = []

      signal_block = lambda do |status|
        results << status
        puts "Finished #{status}".green
      end

      files = files_to_sync

      pool = S3AssetSync::Actors::S3Upload.pool

      start = Time.now

      files.each do |file_path|
        file_info = {
            file_path: file_path,
            base_path: self.rails_asset_path,
            prefix: self.asset_prefix
          }
        pool.async.perform(file_info, signal_block)
      end

      until(results.length === files.length) do
        sleep(0.5)
      end

      done = Time.now

      puts "#{done} : #{results.count} files completed in #{done-start}s."

      results
    end

    def self.sync
      new.sync
    end

  end
end
