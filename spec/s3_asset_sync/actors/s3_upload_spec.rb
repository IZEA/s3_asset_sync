require 'spec_helper'

describe S3AssetSync::Actors::S3Upload do
  let(:file_path) { File.join(Rails.public_path, Rails.application.config.assets.prefix, 'first.js') }
  let(:base_path) { File.join(Rails.public_path, Rails.application.config.assets.prefix) }
  let(:prefix)    { Rails.application.config.assets.prefix.gsub('/','') }

  let(:file_info) do
    {
      file_path: file_path,
      base_path: base_path,
      prefix: prefix
    }
  end

  context "#perform" do
    let(:signal) do
      Proc.new do |status|
        expect(status).not_to be_nil
      end
    end

    it 'puts object, and calls back' do

      subject = S3AssetSync::Actors::S3Upload.new

      entries = {
        acl: 'public-read',
        bucket: S3AssetSync.config.s3_bucket,
        key: "assets/first.js",
        content_type: "application/javascript"
      }

      subject.client.expects(:put_object).with(has_entries(entries)).returns(true)

      subject.perform(file_info, signal)
    end
  end
end
