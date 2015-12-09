# Automatically sync assets with S3 after precompilation.
Rails.application.config.s3_asset_sync.run_after_precompile = true

# Rake tasks to run before syncing to s3
Rails.application.config.s3_asset_sync.rake_task_prereqs = []

# Automatically replace files with their equivalent gzip compressed version
# Rails.application.config.s3_asset_sync.gzip_compression = true

# Configure connection to S3.
Rails.application.config.s3_asset_sync.s3_bucket = "YOUR_BUCKET_NAME"
Rails.application.config.s3_asset_sync.s3_region = "YOUR_REGION"
