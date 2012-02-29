require "cgi"
require "open-uri"
require 'active_support/core_ext/class/attribute_accessors'

module Paypal
	class InvalidRequest < StandardError; end

	class InvalidParameter < StandardError; end

	class PaypalApiError < StandardError; end
end

$:.push File.expand_path("../../lib", __FILE__)

require "paypal_api/version"
require "paypal_api/apis/api"
require "paypal_api/support/parameter"
require "paypal_api/support/response"
require "paypal_api/support/request"
require "generators/paypal/ipn_message_generator"
require "paypal_api/apis/payments_pro"
require "paypal_api/apis/mass_pay"