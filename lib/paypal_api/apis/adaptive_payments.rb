module Paypal
	class AdaptivePayments < Paypal::Api

		def self.to_key(symbol)
			if symbol.is_a?(String)
				return symbol
			else
				case symbol
				when :request_envelope_error_language then
					return "requestEnvelope.errorLanguage"
				# when :reverse_all_parallel_payments_on_error then
				# 	return "reverseAllParallelPaymentsonError" # may just be a typo in docs, need to test
				when :request_envelope then
					return "requestenvelope"
				else
					#camelcaps but first letter is lowercase
					cameled = symbol_to_camel(symbol)
					return cameled[0].downcase + cameled.split(/./, 2).join
				end
			end
		end

		set_request_signature :pay, {
			# standard params
			:action_type => Enum.new({:pay => "PAY", :create => "CREATE", :pay_primary => "PAY_PRIMARY"}),
			:receiver => Sequential.new({
					:email => String,
					:amount => Float,
					:primary => Optional.new(Boolean),
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
				}, 6, lambda {|key, i| "receiverList.receiver(#{i}).#{Paypal::AdaptivePayments.to_key(key)}" }),
			:currency_code => Default.new("USD", String),
			:cancel_url => String,
			:return_url => String,
			:request_envelope_error_language => "en_US",

			# parallel payments
			# 	request is considered parallel if more than one receiver is added
			:reverse_all_parallel_payments_on_error => Optional.new(Boolean)

			# chained payments
			# 	choose one of your receivers to be primary = true and the rest false to initiate a chained payment

			# implicit payments
			# 	if you are the api caller and you put in your own email address here, it is automatically approved
			:sender_email => Optional.new(String)

			# preapproval payments
			# 	if you provide the following, and it is accurate, the payment will automatically be approved
			:preapproval_key => Optional.new(String),
			:pin => String,


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

			:request_envelope => Hash.new({
				:detail_level => Default.new("ReturnAll"),
				:error_language => "en_US"
			}), # docs don't say the options for this...


			:sender => Optional.new(Hash.new({
				:user_credentials => Boolean
			})),

			:tracking_id => Optional.new(String)

		}

	end

	class PayRequest < request
		# customize validation here
		# ...there may be some special cases with this api, i'm not positive yet
	end
end