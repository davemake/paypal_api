class Paypal::Response

	def initialize(stringio)
		@parsed_response = CGI.parse(stringio.class == StringIO ? stringio.read : stringio)
	end

	def []=(key)
		if key.class == Symbol
			@parsed_response[symbol_to_key(key)]
		else
			@parsed_response[key]
		end
	end

	def method_missing?(key)
		return @parsed_response[symbol_to_key(key)]
	end

	private

		def symbol_to_key(symbol)
			return symbol.to_s.upcase
		end
end