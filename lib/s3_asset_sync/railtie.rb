require 'rails/railtie'

module S3AssetSync
  class Railtie < Rails::Railtie
    config.s3_asset_sync = ActiveSupport::OrderedOptions.new

    config.s3_asset_sync.run_after_precompile = true
    config.s3_asset_sync.rake_task_prereqs = []
    config.s3_asset_sync.gzip_compression = false
    config.s3_asset_sync.s3_bucket = "YOUR_BUCKET_NAME"
    config.s3_asset_sync.endpoint = "YOUR_END_POINT"
    config.s3_asset_sync.s3_region = "us-east-1"


    config.after_initialize do
      S3AssetSync.config do |cfg|
        cfg.rails_public_path = Rails.public_path
        cfg.asset_prefix = Rails.application.config.assets.prefix
        cfg.gzip_compression = Rails.application.config.s3_asset_sync.gzip_compression
        cfg.s3_bucket = Rails.application.config.s3_asset_sync.s3_bucket
        cfg.aws_region = Rails.application.config.s3_asset_sync.s3_region
      end
    end

    rake_tasks do
      load "tasks/s3_asset_sync.rake"
      namespace :s3_asset_sync do
        desc "Initialize S3AssetSync configuration."
        task :setup do
          abort("Already found config file. Have you already run this task?.") if File.exist?("config/initializers/s3_asset_sync.rb")

          cp(
            File.expand_path("../../../templates/s3_asset_sync.rb", __FILE__), "config/initializers/s3_asset_sync.rb"
          )
        end
      end
    end
  end
end
