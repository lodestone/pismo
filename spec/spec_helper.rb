require "open-uri"
require "yaml"
require "pismo"

HTML_DIRECTORY = File.expand_path("../spec/corpus", File.dirname(__FILE__)) 
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
