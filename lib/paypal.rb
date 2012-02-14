$:.push File.expand_path("../../lib", __FILE__)

require "paypal/version"
require "paypal/apis/api"
require "paypal/support/response"
require "paypal/support/request"
require "paypal/apis/payments_pro"

require "cgi"
require "open-uri"

module Paypal
	class InvalidRequest < StandardError; end

	class InvalidParameter < StandardError; end

	class PaypalApiError < StandardError; end
end
