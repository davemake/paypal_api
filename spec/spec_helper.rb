require 'rubygems'
require 'bundler/setup'

require 'paypal' # and any other gems you need

RSpec.configure do |config|
  # some (optional) config here
  # config.treat_symbols_as_metadata_keys_with_true_values = true
  config.filter_run_excluding :slow_paypal => true
end