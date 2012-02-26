module Paypal
	class MassPay < Paypal::Api
		set_request_signature :mass_pay, {
			:method => "MassPay",
			:email_subject => Optional.new(String), # max 255 char
			:currency_code => Default.new("USD", String),
			:receiver_type => Default.new("EmailAddress", Enum.new(:email_address => "EmailAddress", :user_id => "UserID")),
			:payee => Sequential.new({
				:email => String,
				:amt => Float,
				:unique_id => Optional.new(String)
			}, 250, lambda {|key, i| "L_#{key.to_s.gsub("_","").upcase}#{i}"})
		}
	end

	class MassPayRequest

		protected
			def validate!
				if @payee.length == 0
					raise Paypal::InvalidRequest, "you pust provide at least one payee"
				end
			end
	end
end