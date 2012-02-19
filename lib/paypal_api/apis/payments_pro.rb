module Paypal
	class PaymentsPro < Paypal::Api

		set_request_signature :do_direct_payment, {

			# DoDirectPayment Request Fields
			:method => "DoDirectPayment",
			:payment_action => Optional.new(Enum.new("Authorization", "Sale")),
			:ip_address =>	/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/,
			:return_mf_details => Optional.new(
				Coerce.new( lambda do |val|
					return [1, "1", true].include?(val) ? 1 : 0
				end)
			),


			# Credit Card Details Fields
			:credit_card_type => Optional.new(Enum.new("Visa", "MasterCard", "Discover", "Amex", "Maestro")),
			:acct => /\d+/, # this should be better
			:exp_date => /^\d{6}$/, # "MMYYYY"
			:cvv2 => /^\d{3,4}$/,
			:start_date => Optional.new(/^\d{6}$/), # maestro only
			:issue_number => Optional.new(/^\d{,2}$/), #maestro only


			# Payer Information Fields
			:email => Optional.new(/email/), # max 127 char
			:first_name => String, # max 25 char
			:last_name => String, # max 25 char


			# Address Fields
			:street => String, # max 100 char
			:street_2 => Optional.new(String), # max 100 char
			:city => String, # max 40 char
			:state => String, # max 40 char
			:country_code => Default.new("US", /^[a-z]{2}$/i),
			:zip => String, # max 20 char
			:ship_to_phone_num => Optional.new(String), # max 20 char


			# Payment Details Fields
			:amt => Float, # complicated: https://www.x.com/developers/paypal/documentation-tools/api/dodirectpayment-api-operation-nvp
			:currency_code => Default.new("USD", /^[a-z]{3}$/i),

			# TODO:
			:item_amt => Optional.new,
			:shipping_amt => Optional.new,
			:insurance_amt => Optional.new,
			:shipdisc_amt => Optional.new,
			:handling_amt => Optional.new,
			:tax_amt => Optional.new,

			:desc => Optional.new(String), # max 127 char
			:custom => Optional.new(String), # max 256 char
			:inv_num => Optional.new(String), # max 127 char
			:button_source => Optional.new(String), # max 32 char

			:notify_url => Optional.new, # hard to tell if this is part of this api or not from the wording in the docs
			:recurring => Default.new("N", lambda {|anything| "Y" }),


			# TODO: Payment Details Item Fields
			# TODO: Ebay Item Payment Details Item Fields
			# TODO: Ship To Address Fields
			# TODO: 3D Secure Request Fields (U.K. Merchants Only)

		}

		set_request_signature :do_reference_transaction, {
			:method => "DoReferenceTransaction",
			:reference_id => String,
			:payment_action => Default.new("Sale", Enum.new("Authorization", "Sale")),
			:return_mf_details => Optional.new(
				Coerce.new( lambda do |val|
					return [1, "1", true].include?(val) ? 1 : 0
				end)
			),
			:soft_descriptor =>Optional.new(lambda {|val|
				if val.match(/^([a-z0-9]|\.|-|\*| )*$/i) && val.length <= 22
					return true
				else
					return false
				end
			}),

			# ship to address fields
			:ship_to_name => Optional.new(String), # max 32
			:ship_to_street => Optional.new(String), # max 100
			:ship_to_street_2 => Optional.new(String), # max 100
			:ship_to_city => Optional.new(String), # max 40
			:ship_to_state => Optional.new(String), # max 40
			:ship_to_zip => Optional.new(String), # max 20
			:ship_to_country => Optional.new(String), # max 2
			:ship_to_phone_num => Optional.new(/[0-9+-]+/), # max 20

			# payment details fields
			:amt => Float,
			:currency_code => Default.new("USD", /^[a-z]{3}$/i),

			# TODO:
			:item_amt => Optional.new,
			:shipping_amt => Optional.new,
			:insurance_amt => Optional.new,
			:shipdisc_amt => Optional.new,
			:handling_amt => Optional.new,
			:tax_amt => Optional.new,

			:desc => Optional.new(String), # max 127 char
			:custom => Optional.new(String), # max 256 char
			:inv_num => Optional.new(String), # max 127 char
			:button_source => Optional.new(String), # max 32 char

			:notify_url => Optional.new, # hard to tell if this is part of this api or not from the wording in the docs
			:recurring => Default.new("N", lambda {|anything| "Y" }),

			:item => Sequential.new({
					:l_item_category => Enum.new("Digital", "Physical")
				})

		}

		set_request_signature :do_capture, {
			:method => "DoCapture",
			:authorization_id => String, # max 19 char
			:amt => Float,
			:currency_code => Default.new("USD", /^[a-z]{3}$/i),
			:complete_type => Default.new("Complete", Enum.new("Complete", "NotComplete")),
			:inv_num => Optional.new(String), # max 127 char
			:note => Optional.new(String), # max 255 char
			:soft_descriptor => Optional.new(lambda {|val|
				if val.match(/^([a-z0-9]|\.|-|\*| )*$/i) && val.length <= 22
					return true
				else
					return false
				end
			}),

			:store_id => Optional.new(String), # max 50 char
			:terminal_id => Optional.new(String) # max 50 char
		}

		set_request_signature :do_void, {
			:method => "DoVoid",
			:authorization_id => String, # Note: If you are voiding a transaction that has been reauthorized, use the ID from the original authorization, and not the reauthorization.
			:note => String # max 255 char
		}

	end
end