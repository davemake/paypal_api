require "paypal/version"
require "paypal/apis/api"
require "paypal/support/response"
require "paypal/support/request"
require "paypal/apis/payments_pro"

module Paypal
	class InvalidRequest < Error; end

	class InvalidParameter < Error; end

	class PaypalApiError < Error; end
end
