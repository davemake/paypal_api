module Paypal
	class Request

		cattr_accessor :environment, :user, :pwd, :signature, :version

		PAYPAL_VERSION = "84.0"
		@@paypal_info = nil
		@@paypal_endpoint = nil

		# class instance variables (unique per subclass, not unique per instance)
		# used for dynamically created request classes
		@required = []
		@sequential = []

		attr_accessor :payload

		def initialize(payload = {})
			config

			@payload = payload
			@payload.each do |k,v|
				self.send("#{k}=", v)
			end
		end

		def valid?
			begin
				params_fulfilled?
				return true
			rescue
				return false
			end
		end

		def self.required_keys
			@required
		end

		def self.sequential_keys
			@sequential
		end

		def paypal_endpoint_with_defaults
			return "#{@@paypal_endpoint}?PWD=#{@@paypal_info["password"] || self.class.pwd}" +
				"&USER=#{@@paypal_info["username"] || self.class.user}" +
				"&SIGNATURE=#{@@paypal_info["signature"] || self.class.signature}" +
				"&VERSION=#{PAYPAL_VERSION}"
		end

		def sequentials_string
			self.class.sequential_keys.map{|k| self.send(k).to_s }.join
		end

		def request_string
			(@payload.keys | self.class.required_keys).inject(paypal_endpoint_with_defaults + sequentials_string) do |acc, key|
				# if key signature is hash or optional...
				"#{acc}&#{to_key(key)}=#{escape_uri_component(self.send(key))}"
			end
		end

		# separated out so as not to stub Kernel.open in tests
		def make_request
			response = open(request_string)
			return Paypal::Response.new(response)

			# if response.kind_of? Net::HTTPSuccess
			# 	puts response.read
			# 	return Response.new(response)
			# else
			# 	raise StandardError
			# end
		end

		def make(&block)
			params_fulfilled?
			begin
				response = make_request

				if block
					yield response
				else
					return response
				end
			rescue OpenURI::HTTPError => error
				status_code = error.io.status[0]
				# Rails.logger.info "[ERROR][Paypal] #{error.message } : #{error.backtrace} " if @@rails
				raise $!
			# rescue Timeout::Error => time_out_error
			# 	Rails.logger.info "[ERROR][Timeout Error] #{time_out_error.message} : #{time_out_error.backtrace}" if @@rails
			# 	raise $!
			rescue => err
				# Rails.logger.info "[ERROR][Something went wrong] #{err.message} : #{err.backtrace}" if @@rails
				raise $!
			end
		end

		private

			include Paypal::Formatters

			def config

				@@paypal_info = {}

				@@paypal_info = get_info if Module.const_defined?("Rails")

				@@paypal_endpoint = (@@paypal_info["environment"] == "production" || Paypal::Request.environment == "production") ? "https://api-3t.paypal.com/nvp" : "https://api-3t.sandbox.paypal.com/nvp"

			end

			def get_info
				YAML.load(::ERB.new(File.new(Rails.root.join("config", "paypal.yml")).read).result)[Rails.env]
			end

			def params_fulfilled?
				self.class.required_keys.each do |method|
					raise Paypal::InvalidRequest, "missing required field: #{method}" if self.send(method).nil?
				end

				# TODO: check if sequential has been fulfilled
			end
	end
end