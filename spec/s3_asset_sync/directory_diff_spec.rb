require 'spec_helper'
require 'ostruct'

describe S3AssetSync::DirectoryDiff do
  subject { S3AssetSync::DirectoryDiff.new }
  context 'initialization' do
    it 'initializes correctly' do
      expect(subject.client).to be_instance_of(Aws::S3::Client)

      expect(subject.bucket).to eq(S3AssetSync.config.s3_bucket)
      expect(subject.asset_prefix).to eq(S3AssetSync.config.asset_prefix.gsub('/',''))
      expect(subject.rails_public_path).to eq(Rails.public_path)
      expect(subject.rails_asset_path).to eq(File.join(Rails.public_path, Rails.application.config.assets.prefix))
    end
  end

  def list_object_results(count = 1)
    results = OpenStruct.new({ contents: [], is_truncated: false })

    count.times do |number|
      results.contents << OpenStruct.new(key: "assets/test/file_#{number}.js")
    end

    results
  end

  context '#files_in_bucket' do
    it 'requests items from AWS' do
      Aws::S3::Client.any_instance.expects(:list_objects_v2).returns(list_object_results)

      list = subject.files_in_bucket

      expect(list.count).to eq(1)
      expect(list).to includes('assets/test/file_0.js')
    end
  end

  context '#files_to_sync' do
    it 'finds the correct number of files' do
      files = subject.files_to_sync
      expect(files.count).to eq(5)
    end
    it 'files are returned as key names' do
      files = subject.files_to_sync
      files.each do |file|
        expect(file).to start_with(subject.asset_prefix)
      end
    end
    it 'excludes sprockets manifest' do
      files = subject.files_to_sync
      files.each do |file|
        expect(file).not_to match(S3AssetSync::SPROCKETS_MANIFEST)
      end
    end
  end

  context '#difference' do
    before(:each) do
      object_results = list_object_results(5)
      object_results.contents << OpenStruct.new(key: 'assets/first.js')
      Aws::S3::Client.any_instance.expects(:list_objects_v2).returns(object_results)
    end

    it 'returns the items in the remote list that are not local' do
      diffs = subject.difference

      expect(diffs.count).to eq(5)
    end

    it 'no local files should exist in the list' do
      diffs = subject.difference
      files = subject.files_to_sync
      files.each do |file|
        expect(diffs).not_to includes(file)
      end
    end
  end

  context '#clean_differences' do
    it 'deletes objects from s3 in bulk' do
      Aws::S3::Client.any_instance.expects(:list_objects_v2).at_least_once.returns(list_object_results(5))
      Aws::S3::Client.any_instance.expects(:delete_objects).returns(true)
      subject.clean_differences
    end

    it 'splits up bulk requests when needed' do
      Aws::S3::Client.any_instance.expects(:list_objects_v2).at_least_once.returns(list_object_results(1000))
      Aws::S3::Client.any_instance.expects(:delete_objects).twice.returns(true)
      subject.clean_differences
    end
  end

end
