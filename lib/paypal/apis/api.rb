class Paypal::Api

	attr_accessor :request

	def self.emails_and_amounts(payouts)
		return payouts.each_with_index.inject("") do |acc, (payout, i)|
			# documentation doesn't agree as to whether or not there is a unique id field here
			acc+"&L_EMAIL#{i}=#{escape_uri_component(payout.payee.email)}&L_AMT#{i}=#{escape_uri_component(payout.amount.round(2))}&L_UNIQUEID#{i}=#{escape_uri_component(payout.unique_id)}"
		end
	end

	def self.escape_uri_component(string)
		string = string.to_s
		return URI.escape(string, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
	end

	class Parameter
		attr_accessor :value

		def initialize(value)
			@value = value
		end

		def parse(anything)
			@value = anything
			return @value
		end
	end

	class Default < Parameter

		def initialize(value, parameter)
			@value = value
			@parameter = parameter
		end

		def parse(val)
			@value = @parameter.parse(val)
			return @value
		end

	end

	class Coerce < Parameter

		attr_reader :method

		def initialize(method)
			@method = method
		end
	end

	class Enum < Parameter

		# needs to return the exact string if given instead of symbol
		attr_reader :allowed_values

		def initialize(*values)
			@allowed_values = values
		end

		def parse(val)
			# TODO: coerce between
			if @allowed_values.include?(val)
				return val
			else
				raise InvalidParameter
			end
		end
	end

	class Optional < Parameter
		def initialize(parameter = nil)
			@parameter = parameter
		end

		def parse(val)
			if @parameter.class == Class
				if val.class == parameter
					return val
				else
					raise InvalidParameter
				end
			elsif @parameter.class == Regexp
				match = parameter.match(val)
				if match
					return match[0]
				else
					raise InvalidParameter
				end
			elsif @parameter.class < Parameter
				begin
					return @parameter.parse(val)
				rescue InvalidParameter
					return nil
				end
			else
				return val
			end
		end
	end


	protected

		def set_accessor(klass, name, type = nil)
			set_reader(klass, name, type)
			set_writer(klass, name, type)
		end

		def to_key(symbol)
			return symbol.to_s.gsub(/[^a-z0-9]/i, "").upcase
		end

		def set_value_for_type(field, type, val)
			# arbitrary value
			if type.nil?
				instance_variable_set("@#{field}", val)
			# special types
			elsif type.class == Regexp
				instance_variable_set("@#{field}", type.parse(val))
			elsif type.class == Optional
				instance_variable_set("@#{field}", type.parse(val))
			elsif type.class == Enum
				instance_variable_set("@#{field}", type.parse(val))
			elsif type.class == Coerce
				instance_variable_set("@#{field}", type.parse(val))
			elsif type.class == Default
				instance_variable_set("@#{field}", type.parse(val))
			# custom type
			elsif type.class == Proc && type.call(val)
				instance_variable_set("@#{field}", val)
			# is_a type
			elsif type == val.class
				instance_variable_set("@#{field}",val)
			else
				raise Paypal::InvalidParameter
			end
		end

		# writers should validate before assigning value
		def set_writer(klass, m, type)
			klass.define_method("#{m}=") do |val|
				set_value_for_type(m, type, val)
			end
		end

		def set_reader(klass, m, type, constant = false)
			variable = "@#{m}"

			klass.define_method(m) do
				if constant
					return type
				elsif type == Default
					instance_variable_set(variable, type.value) unless instance_variable_defined?(variable)
					instance_variable_get(variable)
				else
					instance_variable_get(variable)
				end
			end
		end

		def set_required(klass, keys)
			klass.class_eval do
				class_variable_set("@@required", keys)
			end
		end

		def symbol_to_camel(symbol)
			return symbol.to_s.downcase.split("_").map(&:capitalize).join
		end

		def set_request_signature(name, hash)
			# create request object
			class_name = "#{symbol_to_camel name}Request"
			self.class.class_eval <<-EOS
			  class #{class_name} < Request; end
			EOS
			klass = Kernel.const_get(class_name)

			# add setters/getters
			required = []
			hash.each do |k,v|
				if v.class == String || v.class == Fixnum || v.class == Float
					set_reader klass, k, v, true
				else
					set_accessor klass, k, v
				end

				required.push(k) unless v.class == Optional
			end

			# set which keys are required for the request
			set_required(klass, required)

			# create api method
			self.define_class_method <<-EOS
				def self.#{name}(hash = {})
					return #{klass}.new(hash)
				end
			EOS
		end

		def set_response_signature(hash)
			hash.each do |k,v|
				set_reader k, v
			end
		end

end