class Paypal::Request

	if defined? Rails
		PAYPAL_INFO = YAML::load(File.open("#{Rails.root}/config/paypal_adaptive.yml"))[Rails.env]
	else
		PAYPAL_INFO = {}
	end

	PAYPAL_VERSION = "2.3"
	PAYPAL_ENDPOINT = PAYPAL_INFO["environment"] == "production" ? "https://api-3t.paypal.com/nvp" : "https://api-3t.sandbox.paypal.com/nvp"

	@@required = []
	@@sequential = []

	attr_accessor :payload

	def initialize(payload = {})
		@payload = payload
		@payload.each do |k,v|
			self.send("#{k}=", v)
		end
	end

	def required_keys
		@@required
	end

	def paypal_endpoint_with_defaults
		return "#{PAYPAL_ENDPOINT}?PWD=#{PAYPAL_INFO["password"]}" +
			"&USER=#{PAYPAL_INFO["username"]}" +
			"&SIGNATURE=#{PAYPAL_INFO["signature"]}" +
			"&VERSION=#{PAYPAL_VERSION}"
	end

	def sequentials_string
		@@sequential.map{|k| self.send(k).to_s }.join
	end

	def request_string
		(@payload.keys | @@required).inject(paypal_endpoint_with_defaults + sequentials_string) do |acc, key|
			"#{acc}&#{to_key(key)}=#{escape_uri_component(self.send(key))}"
		end
	end

	# separated out so as not to stub Kernel.open
	def make_request
		response = open(request_string)
		return Response.new(response)
	end

	def make(&block)
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

		def emails_and_amounts(payouts)
			return payouts.each_with_index.inject("") do |acc, (payout, i)|
				# documentation doesn't agree as to whether or not there is a unique id field here
				acc+"&L_EMAIL#{i}=#{escape_uri_component(payout.payee.email)}&L_AMT#{i}=#{escape_uri_component(payout.amount.round(2))}&L_UNIQUEID#{i}=#{escape_uri_component(payout.unique_id)}"
			end
		end

		include Paypal::Formatters

		def params_fulfilled?
			@@required.each do |method|
				raise Paypal::InvalidRequest if self.send(method).nil?
			end
		end
end