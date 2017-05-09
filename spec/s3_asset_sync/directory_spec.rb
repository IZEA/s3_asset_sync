require 'spec_helper'

describe S3AssetSync::Directory do
  context '#initialize' do
    it 'gets settings correctly' do
      subject = S3AssetSync::Directory.new
      expect(subject.rails_public_path).to eq(Rails.public_path)
      expect(subject.rails_asset_path).to eq(File.join(Rails.public_path, Rails.application.config.assets.prefix))
      expect(subject.asset_prefix).to eq(Rails.application.config.assets.prefix.gsub('/',''))
    end
  end
  context '#files_to_sync' do
    it 'lists the correct number of files' do
       subject = S3AssetSync::Directory.new
      expect(subject.files_to_sync.count).to eq(5)
    end
  end
  context '#sync' do
    it 'performs the correct number of times' do
      subject = S3AssetSync::Directory.new
      perform = Proc.new do |file_info, signal_block|
        expect(file_info).to have_key(:file_path)
        expect(file_info).to have_key(:base_path)
        expect(file_info).to have_key(:prefix)
        expect(signal_block).to respond_to(:call)

        signal_block.call(file_info)
      end

      proxy = stub('proxy')
      proxy.stubs(:perform).with(&perform)
      proxy1 = stub('proxy1')
      proxy1.stubs(:async).returns(proxy)
      subject.stubs(:pool).returns(proxy1)

      results = subject.sync

      expect(results.length).to eq(5)
    end
  end
end
