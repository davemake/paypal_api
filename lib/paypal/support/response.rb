class Paypal::Response

	attr_accessor :raw_response, :parsed_response

	def initialize(stringio)
		@raw_response = stringio.class == StringIO ? stringio.read : stringio
		@parsed_response = CGI.parse(@raw_response)

		@success = @parsed_response["ACK"] == ["Success"]
		# raise PaypalApiError if @parsed_response["ACK"] == "Failure"
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

	private

		def symbol_to_key(symbol)
			return symbol.to_s.gsub(/[^0-9a-z]/i, "").upcase
		end
end