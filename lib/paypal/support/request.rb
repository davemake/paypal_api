class Paypal::Request

	PAYPAL_INFO = YAML::load(File.open("#{Rails.root}/config/paypal_adaptive.yml"))[Rails.env]
	PAYPAL_VERSION = "2.3"
	PAYPAL_ENDPOINT = PAYPAL_INFO["environment"] == "production" ? "https://api-3t.paypal.com/nvp" : "https://api-3t.sandbox.paypal.com/nvp"

	@@required = []

	attr_accessor :payload

	def initialize(payload)
		@payload = payload
		@payload.each do |k,v|
			self.send("#{k}=", v)
		end
	end

	def paypal_endpoint_with_defaults
		return "#{PAYPAL_ENDPOINT}?PWD=#{PAYPAL_INFO["password"]}" +
			"&USER=#{PAYPAL_INFO["username"]}" +
			"&SIGNATURE=#{PAYPAL_INFO["signature"]}" +
			"&VERSION=#{PAYPAL_VERSION}"
	end

	def request_string
		@payload.inject(paypal_endpoint_with_defaults) do |acc, arr|
			"#{acc}&#{escape_uri_component(arr[0])}=#{escape_uri_component(arr[1])}"
		end
	end

	# separated out so as not to stub Kernel.open
	def make_request
		response = open(request_string)
		return Response.new(response)
	end

	def make(&block)
		validate
		params_fulfilled?
		begin
			response = nil
			response = make_request

			if block
				yield response
			else
				return response
			end
		rescue OpenURI::HTTPError => error
			status_code = error.io.status[0]
			Rails.logger.info "[ERROR][Paypal] #{error.message } : #{error.backtrace} "
			raise $!
		rescue Timeout::Error => time_out_error
			Rails.logger.info "[ERROR][Timeout Error] #{time_out_error.message} : #{time_out_error.backtrace}"
			raise $!
		rescue => err
			Rails.logger.info "[ERROR][Something went wrong] #{err.message} : #{err.backtrace}"
			raise $!
		end
	end

	private

		def params_fulfilled?
			@@required.each do |method|
				raise InvalidRequest if self.send(method).nil?
			end
		end
end