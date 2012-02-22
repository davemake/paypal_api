module Paypal
	class Response

		attr_accessor :raw_response, :parsed_response, :error_code

		def initialize(stringio)
			@raw_response = stringio.class == StringIO ? stringio.read : stringio
			@parsed_response = CGI.parse(@raw_response)

			@success = @parsed_response["ACK"] == ["Success"]

			unless @success
				@error_message = @parsed_response["L_LONGMESSAGE0"][0]
				@error_code = @parsed_response["L_ERRORCODE0"][0]
			end
		end

		def [](key)
			if key.class == Symbol
				@parsed_response[symbol_to_key(key)][0]
			else
				@parsed_response[key][0]
			end
		end

		def success?
			return @success
		end

		def method_missing?(key)
			return @parsed_response[symbol_to_key(key)]
		end

		def error_input
			@@error_codes[@error_code]
		end

		def error_field
			@@error_codes[@error_code] ? @@human_readable[@@error_codes[@error_code]] : nil
		end

		def error_message
			@error_message + "[#{@error_code}]"
		end

		private

			def symbol_to_key(symbol)
				return symbol.to_s.gsub(/[^0-9a-z]/i, "").upcase
			end
	end
end

class Paypal::Response
	@@error_codes = {
		'10527' => :acct,
		'10525' => :amt,
		'10508' => :exp_date,
		'10504' => :cvv2,
		'10502' => :acct,
		'10501' => :reference_id,
		'10509' => :ip_address,
		'10510' => :acct,
		'10519' => :acct,
		'10521' => :acct,
		'10526' => :currency_code
	}

	@@human_readable = {
		:acct => "credit card number",
		:amt => "charge amount",
		:exp_date => "expiration date",
		:cvv2 => "security code",
		:reference_id => "billing agreement",
		:currency_code => "currency code"
	}
end