# note: things got a little weird here because the paypal apis
# 	are so different, but i tried to make it work smoothly... at least
# 	it is from outside interaction... wahhh

module Paypal

	class AdaptivePaymentsResponse < Response
		def initialize(stringio)
			@raw_response = stringio.class == StringIO ? stringio.read : stringio
			@parsed_response = CGI.parse(@raw_response)

			@success = @parsed_response["responseEnvelope.ack"] == ["Success"]

			unless @success
				# "responseEnvelope.timestamp"=>["2012-02-29T13:35:28.528-08:00"],
				# "responseEnvelope.ack"=>["Failure"],
				# "responseEnvelope.correlationId"=>["ca0befbd1fe0b"],
				# "responseEnvelope.build"=>["2486531"],
				# "error(0).errorId"=>["560022"],
				# "error(0).domain"=>["PLATFORM"],
				# "error(0).subdomain"=>["Application"],
				# "error(0).severity"=>["Error"],
				# "error(0).category"=>["Application"],
				# "error(0).message"=>["The X-PAYPAL-APPLICATION-ID header contains an invalid value"],
				# "error(0).parameter(0)"=>["X-PAYPAL-APPLICATION-ID"]

				@error_message = @parsed_response["error(0).message"][0]
				@error_code = @parsed_response["error(0).errorId"][0]
				@paypal_error_field = @parsed_response["error(0).parameter(0)"][0]
			end
		end

		protected

			def symbol_to_key(symbol)
				case symbol
				when :correlation_id
					return "responseEnvelope.correlationId"
				else
					return Paypal::Api.symbol_to_lower_camel(symbol)
				end
			end
	end

	class AdaptivePaymentsRequest < Request
		# customize validation here
		attr_accessor :ip_address

		def self.api_endpoint
			"https://svcs.paypal.com/AdaptivePayments/#{api_method.capitalize}"
		end

		def self.api_sandbox_endpoint
			"https://svcs.sandbox.paypal.com/AdaptivePayments/#{api_method.capitalize}"
		end

		def headers
			{
				"X-PAYPAL-SECURITY-USERID" => user,
				"X-PAYPAL-SECURITY-PASSWORD" => password,
				"X-PAYPAL-SECURITY-SIGNATURE" => signature,
				"X-PAYPAL-DEVICE-IPADDRESS" => @ip_address,
				"X-PAYPAL-REQUEST-DATA-FORMAT" => "NV",
				"X-PAYPAL-RESPONSE-DATA-FORMAT" => "NV",
				"X-PAYPAL-APPLICATION-ID" => application_id
			}
		end

		def process_response(response)
			return AdaptivePaymentsResponse.new(response)
		end

		def make_request
			if @ip_address.nil?
				throw Paypal::InvalidRequest, "need an ip address"
			else
				super
			end
		end

		def to_key(symbol)
			if symbol.is_a?(String)
				return symbol
			else
				case symbol
				when :request_envelope_error_language then
					return "requestEnvelope.errorLanguage"
				# when :reverse_all_parallel_payments_on_error then
				# 	return "reverseAllParallelPaymentsonError" # may just be a typo in docs, need to test
				when :request_envelope_detail_level then
					return "requestEnvelope.detailLevel"
				when :sender_use_credentials
					return "sender.useCredentials"
				when :method
					return "METHOD"
				else
					#camelcaps but first letter is lowercase
					return Paypal::Api.symbol_to_lower_camel(symbol)
				end
			end
		end
	end

	class AdaptivePayments < Paypal::Api

		set_request_signature :pay, {
			# standard params
			:action_type => Enum.new({:pay => "PAY", :create => "CREATE", :pay_primary => "PAY_PRIMARY"}),
			:receiver => Sequential.new({
					:email => String,
					:amount => Float,
					:primary => Optional.new(bool_class),
					:invoice_id => Optional.new(String), # max 127 char
					:payment_type => Optional.new(Enum.new({
						:goods => "GOODS",
						:service => "SERVICE",
						:personal => "PERSONAL",
						:cash_advance => "CASHADVANCE",
						:digital_goods => "DIGITALGOODS"
					})),
					:payment_sub_type => Optional.new(String),
					:phone => Optional.new({
						:country_code => String,
						:phone_number => String,
						:extension => Optional.new(String)
					})
				}, 6, lambda {|key, i| "receiverList.receiver(#{i}).#{Paypal::AdaptivePaymentsRequest.new.to_key(key)}" }),
			:currency_code => Default.new("USD", String),
			:cancel_url => String,
			:return_url => String,

			# parallel payments
			# 	request is considered parallel if more than one receiver is added
			:reverse_all_parallel_payments_on_error => Optional.new(bool_class),

			# chained payments
			# 	choose one of your receivers to be primary = true and the rest false to initiate a chained payment

			# implicit payments
			# 	if you are the api caller and you put in your own email address here, it is automatically approved
			:sender_email => Optional.new(String),

			# preapproval payments
			# 	if you provide the following, and it is accurate, the payment will automatically be approved
			:preapproval_key => Optional.new(String),
			:pin => Optional.new(String),


			:client_details => Optional.new({
				:application_id => String,
				:customer_id => String,
				:customer_type => String,
				:device_id => String,
				:geo_location => String,
				:ip_address => String,
				:model => String,
				:partner_name => String
			}),
			:fees_payer => Optional.new(Enum.new({
				:sender => "SENDER",
				:primary_receiver => "PRIMARYRECEIVER",
				:each_receiver => "EACHRECEIVER",
				:secondary_only => "SECONDARYONLY"
			})),
			# note: FundingConstraint is unavailable to API callers with standard permission levels; for more information, refer to the section Adaptive Payments Permission Levels.
			# maybe collapse into a sequential w proc
			:funding_constraint => Sequential.new({
				:funding_type => Enum.new({:e_check => "ECHECK", :balance => "BALANCE", :credit_card => "CREDITCARD"})
			}, nil, lambda {|key, i| "fundingConstraint.allowedFundingType(#{i}).fundingTypeInfo.#{Paypal::PaymentsPro.to_key(key)}"}),
			:ipn_notification_url => Optional.new(String),
			:memo => Optional.new(String), # max 1000 char

			:request_envelope_error_language => "en_US",
			:request_envelope_detail_level => Default.new("ReturnAll", Optional.new(String)),

			:sender_user_credentials => Optional.new(bool_class),

			:tracking_id => Optional.new(String)

		}

	end
end