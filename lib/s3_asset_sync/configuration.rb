module S3AssetSync
  class Configuration
    attr_accessor :rails_public_path,
                  :asset_prefix,
                  :gzip_compression,
                  :aws_region,
                  :s3_bucket

  end
end
