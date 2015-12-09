require "colorize"
require "aws-sdk-core"
require "s3_asset_sync/railtie" if defined?(Rails)

module S3AssetSync

  ##
  # Loops through /public/assets directory and sync's each
  # file with the specified S3 Bucket.
  #
  def self.sync
    puts "Syncing assets to S3...".yellow

    s3 = Aws::S3::Client.new(region: Rails.application.config.s3_asset_sync.s3_region)

    sync_directory(s3, "")

    puts "Asset sync successfully completed...".green
  end

  def self.sync_directory(s3, path)
    assets_dir = File.join(Rails.public_path, Rails.application.config.assets.prefix)
    gzip = Rails.application.config.s3_asset_sync.gzip_compression

    current_dir = "#{assets_dir}#{path}"
    Dir.foreach(current_dir) do |file|
      next if file == "." || file == ".."
      file_path = File.join(path, file)
      file_key = File.join(Rails.application.config.assets.prefix, path, file)[1..-1]
      full_file_path = "#{assets_dir}#{path}/#{file}"

      if File.file?(full_file_path)
        if gzip && File.extname(file_key) == ".gz"
          puts "SKIP: #{file_key}"
        elsif gzip && File.exist?("#{full_file_path}.gz")
          s3_upload_object(s3, "#{full_file_path}.gz", file_key)
        else
          s3_upload_object(s3, full_file_path, file_key)
        end
      elsif File.directory?(full_file_path)
        sync_directory(s3, file_path)
      end
    end
  end

  ##
  # Loops through specified S3 Bucket and checks to see if the object
  # exists in our /public/assets folder. Deletes it from the
  # bucket if it doesn't exist.
  #
  def self.purge
    puts "Cleaning assets in S3...".yellow

    s3 = Aws::S3::Client.new(region: Rails.application.config.s3_asset_sync.s3_region)

    keys = []

    s3.list_objects(bucket: Rails.application.config.s3_asset_sync.s3_bucket).each do |response|
      keys += response.contents.map(&:key)
    end

    keys.each do |key|
      fn = File.join(Rails.public_path, key)
      unless File.exist?(fn)
        s3_delete_object(s3, key)
        puts "DELETED: #{key}"
      end
    end

    puts "Asset clean successfully completed...".green
  end

  ##
  # Check if a key exists in the specified S3 Bucket.
  #
  def self.s3_object_exists?(client, key)
    client.head_object(
      bucket: Rails.application.config.s3_asset_sync.s3_bucket,
      key: key
    )
    return true
  rescue
    return false
  end

  ##
  # Uploads an object to the specified S3 Bucket.
  #
  def self.s3_upload_object(client, file_path, key)
    puts "SYNC: #{key}"

    ext = File.extname(key)[1..-1] # e.g. "gif"
    mime = Mime::Type.lookup_by_extension(ext).to_s # unknown type will be ""

    file = {
      acl: "public-read",
      bucket: Rails.application.config.s3_asset_sync.s3_bucket,
      body: File.open(file_path),
      key: key,
      content_type: mime
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

    client.put_object(file)
  end

  ##
  # Deletes an object from the specified S3 Bucket.
  #
  def self.s3_delete_object(client, key)
    client.delete_object(
      bucket: Rails.application.config.s3_asset_sync.s3_bucket,
      key: key
    )
  end

end
