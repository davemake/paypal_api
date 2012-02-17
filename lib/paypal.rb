$:.push File.expand_path("../../lib", __FILE__)

# require "paypal_api/version"
# require "paypal_api/apis/api"
# require "paypal_api/support/response"
# require "paypal_api/support/request"
# require "paypal_api/apis/payments_pro"

require "cgi"
require "open-uri"

module Paypal
	class InvalidRequest < StandardError; end

	class InvalidParameter < StandardError; end

	class PaypalApiError < StandardError; end
end
