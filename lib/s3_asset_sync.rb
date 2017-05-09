require 'rails'
require "aws-sdk-core"
require "colorize"
require "s3_asset_sync/railtie" if defined?(::Rails::Railtie)
require "s3_asset_sync/configuration"
require "s3_asset_sync/directory"
require "s3_asset_sync/directory_diff"


module S3AssetSync
  SPROCKETS_MANIFEST = /\.sprockets-manifest-(\w)+.json$/

  ##
  # Contains settings.
  # S3AssetSync.config do |config|
  #   config.s3_bucket = Rails.application.config.s3_asset_sync.s3_bucket
  # end
  #
  def self.config
    @configuration ||= Configuration.new
    yield @configuration if block_given?
    @configuration
  end

  ##
  # Loops through /public/assets directory and sync's each
  # file with the specified S3 Bucket.
  #
  def self.sync
    puts "Syncing assets to S3...".yellow

    S3AssetSync::Directory.sync

    puts "Asset sync successfully completed...".green
  end

  ##
  # Loops through specified S3 Bucket and checks to see if the object
  # exists in our /public/assets folder. Deletes it from the
  # bucket if it doesn't exist.
  #
  def self.purge
    puts "Cleaning assets in S3...".yellow

    S3AssetSync::DirectoryDiff.clean_differences

    puts "Asset clean successfully completed...".green
  end

end
