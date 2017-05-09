$:.push File.expand_path("../lib", __FILE__)

require "s3_asset_sync/version"

Gem::Specification.new do |s|
  s.name        = "s3_asset_sync"
  s.version     = S3AssetSync::VERSION
  s.authors     = ["Neil Turner"]
  s.email       = ["neil@neilturner.me"]
  s.homepage    = "https://github.com/neilturner77/s3_asset_sync"
  s.summary     = "Simple way to syncronise your Rails 4 assets with an AWS S3 Bucket."
  s.description = "Simple way to syncronise your Rails 4 assets with an AWS S3 Bucket."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib,templates}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency 'rails', '>= 4.0'
  s.add_dependency 'colorize'
  s.add_dependency 'aws-sdk', '~> 2.9.15'
  s.add_dependency 'celluloid', '>= 0.18.0.pre'
  s.add_dependency 'celluloid-io'
  s.add_dependency 'mime-types', '~> 2.99'

  s.add_development_dependency 'combustion', '~> 0.6.0'
  s.add_development_dependency 'autotest-standalone'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'mocha'
end
