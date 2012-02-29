module Paypal
	class Request

		cattr_accessor :environment, :user, :pwd, :signature, :version, :application_id

		PAYPAL_VERSION = "84.0"
		@@paypal_info = nil
		@@paypal_endpoint = nil

		# class instance variables (unique per subclass, not unique per instance)
		# used for dynamically created request classes
		@required = []
		@sequential = []

		attr_accessor :payload, :error_message, :test_request

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
				validate!
				return true
			rescue
				@error_message = $!.message
				return false
			end
		end

		def self.required_keys
			@required
		end

		def self.sequential_keys
			@sequential
		end

		def request_host
			URI.parse(@@paypal_endpoint).host
		end

		def paypal_endpoint_with_defaults
			return "#{@@paypal_endpoint}?PWD=#{password}" +
				"&USER=#{user}" +
				"&SIGNATURE=#{signature}" +
				"&VERSION=#{version}"
		end

		def sequentials_string
			self.class.sequential_keys.map{|k| self.send(k).to_query_string }.join
		end

		def to_key(symbol)
			return symbol.to_s.gsub(/[^a-z0-9]/i, "").upcase
		end

		def request_string
			(@payload.keys | self.class.required_keys).inject(paypal_endpoint_with_defaults + sequentials_string) do |acc, key|
				# if key signature is hash or optional...
				"#{acc}&#{to_key(key)}=#{escape_uri_component(self.send(key))}"
			end
		end

		# separated out so as not to stub Kernel.open in tests
		def make_request
			response = nil
			if self.respond_to? :headers
				uri = URI.parse(request_string)

				http = Net::HTTP.new(uri.host, uri.port)
				http.set_debug_output $stderr if @test_request
				http.use_ssl = true
				http.verify_mode = OpenSSL::SSL::VERIFY_NONE

				request = Net::HTTP::Get.new(uri.request_uri)
				headers.each do |k,v|
					request[k] = v
				end

				response = http.request(request).body
			else
				$stderr.puts(request_string) if @test_request

				response = open(request_string)
			end

			return process_response(response)
		end

		def process_response(response)
			Paypal::Response.new(response)
		end

		def make(&block)
			params_fulfilled?
			validate!

			response = make_request

			if block
				yield response
			else
				return response
			end

			do_request = lambda {

			}

			if @test_request
				do_request.call
			else
				begin
					do_request.call
				rescue OpenURI::HTTPError => error
					# status_code = error.io.status[0]
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
		end

		protected

			include Paypal::Formatters

			def user
				@@paypal_info["username"] || self.class.user
			end

			def signature
				@@paypal_info["signature"] || self.class.signature
			end

			def password
				@@paypal_info["password"] || self.class.pwd
			end

			def application_id
				@@paypal_info["application_id"] || self.class.application_id
			end

			def version
				self.class.version || PAYPAL_VERSION
			end

			# override for custom request validation
			def validate!
				return true
			end

			# for completeness
			def self.parent_api
				return nil
			end

			def self.api_method
				""
			end

			def self.api_endpoint
				"https://api-3t.paypal.com/nvp"
			end

			def self.api_sandbox_endpoint
				"https://api-3t.sandbox.paypal.com/nvp"
			end

			def config

				@@paypal_info = {}

				@@paypal_info = get_info if Module.const_defined?("Rails") && (Module.const_get("Rails").respond_to?(:root) && !Module.const_get("Rails").root.nil?)

				@@paypal_endpoint = (@@paypal_info["environment"] == "production" || Paypal::Request.environment == "production") ? self.class.api_endpoint : self.class.api_sandbox_endpoint

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