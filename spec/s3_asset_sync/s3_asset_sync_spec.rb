require 'spec_helper'

describe S3AssetSync do
  it "defines the proper methods" do
    expect(subject.respond_to?(:sync)).to be_truthy
    expect(subject.respond_to?(:purge)).to be_truthy
  end
  describe '#sync' do
    it "calls Directory#sync" do
      S3AssetSync::Directory.expects(:sync).returns(true)

      subject.sync
    end
  end
  describe '#purge' do
    it "calls Directory#sync" do
      S3AssetSync::DirectoryDiff.expects(:clean_differences).returns(true)

      subject.purge
    end
  end
end
