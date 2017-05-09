require 'bundler'

Bundler.require :default, :development

Combustion.initialize! :sprockets do

  config.s3_asset_sync.s3_region = "us-east-1"
  config.s3_asset_sync.s3_bucket = "concurrent-asset-test"

end

require 'rspec/rails'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :mocha

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
