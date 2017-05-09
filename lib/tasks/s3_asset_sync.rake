namespace :assets do
  desc "Synchronize all compiled assets to Amazon S3"
  task sync_to_s3: :environment do
    S3AssetSync.sync
  end

  desc "Remove any expired assets stored on Amazon S3"
  task purge_s3: :environment do
    S3AssetSync.purge
  end

  desc "Show asset_sync_config"
  task sync_config: :environment do
    puts S3AssetSync.config.s3_bucket
    puts S3AssetSync.config.aws_region
  end
end

if Rake::Task.task_defined?("assets:precompile")
  Rake::Task["assets:precompile"].enhance do
    if defined?(Rails) && Rails.application.config.s3_asset_sync.run_after_precompile
      Rake::Task["assets:sync_to_s3"].enhance(Rails.application.config.s3_asset_sync.rake_task_prereqs)
      Rake::Task["assets:sync_to_s3"].invoke
    end
  end
end
