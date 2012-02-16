class Paypal::MassPay < Paypal::Api
	MAX_PAYMENTS_PER_CALL = 250

	set_request_signature :mass_pay, {
		:method => "MassPay",
		:email_subject => String,
		:currency_code => Default.new("USD", String),
		:receiver_type => Default.new("EmailAddress", Enum.new("EmailAddress")), # look up other options
		:payee => Sequential.new({
			:l_email => String,
			:l_amt => Float,
			:l_unique_id => Optional.new(String)
		})
	}
end