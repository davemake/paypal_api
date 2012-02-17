module Paypal
	module Formatters
		def escape_uri_component(string)
			string = string.to_s
			return URI.escape(string, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
		end

		def to_key(symbol)
			return symbol.to_s.gsub(/[^a-z0-9]/i, "").upcase
		end
	end

	class Api

		attr_accessor :request

		protected

			def self.set_accessor(klass, name, type = nil)
				set_reader(klass, name, type)
				set_writer(klass, name, type)
			end

			# writers should validate before assigning value
			def self.set_writer(klass, field, type)
				klass.class_eval do
					define_method("#{field}=") do |val|
						# arbitrary value
						if type.nil?
							instance_variable_set("@#{field}", val)
						# special types
						elsif type.class == Regexp
							if match = type.match(val)
								instance_variable_set("@#{field}", match[0])
							else
								raise Paypal::InvalidParameter, "#{field} expects a string that matches #{type}"
							end
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
							raise Paypal::InvalidParameter, "#{field}'s spec was set incorrectly"
						end
					end
				end
			end

			def self.set_reader(klass, m, type, constant = false)
				variable = "@#{m}"

				klass.class_eval do
					define_method(m) do
						if constant
							return type
						elsif type.class == Default
							instance_variable_set(variable, type.value) unless instance_variable_defined?(variable)
							instance_variable_get(variable)
						else
							instance_variable_get(variable)
						end
					end
				end
			end

			def self.set_sequential_reader(klass, k, v)
				variable = "@#{k}"

				klass.class_eval do
					define_method(k) do
						instance_variable_set(variable, v) unless instance_variable_defined?(variable)
						instance_variable_get(variable)
					end
				end
			end

			def self.set_required(klass, keys)
				klass.class_eval do
					@required = keys
				end
			end

			def self.set_sequential(klass, keys)
				klass.class_eval do
					@sequential = keys
				end
			end

			def self.symbol_to_camel(symbol)
				return symbol.to_s.downcase.split("_").map(&:capitalize).join
			end

			def self.set_request_signature(name, hash)
				# create request object
				class_name = "#{self.symbol_to_camel name}Request"
				self.class.class_eval <<-EOS
				  class Paypal::#{class_name} < Request; end
				EOS
				klass = Kernel.const_get("Paypal").const_get(class_name)

				# add setters/getters
				required = []
				sequential = []
				hash.each do |k,v|
					if v.class == String || v.class == Fixnum || v.class == Float
						set_reader klass, k, v, true
					elsif v.class == Sequential
						set_sequential_reader klass, k, v
					else
						set_accessor klass, k, v
					end

					required.push(k) unless v.class == Optional || v.class == Sequential
					sequential.push(k) if v.class == Sequential
				end

				# set which keys are required for the request
				set_required(klass, required)
				set_sequential(klass, sequential)

				# create api method
				self.class_eval <<-EOS
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

end

module Paypal

	class Api

		class Parameter
			attr_accessor :value

			def initialize(value)
				@value = value
			end

			def parse(anything)
				@value = anything
				return @value
			end

			def parameter_parse(val)
				if @parameter.class == Class
					if val.class == @parameter
						return val
					else
						raise Paypal::InvalidParameter, "#{val} is not of type #{val.class}"
					end
				elsif @parameter.class == Regexp
					match = @parameter.match(val)
					if match
						return match[0]
					else
						raise Paypal::InvalidParameter, "#{val} does not match #{@parameter}"
					end
				elsif @parameter.class < Parameter
					return @parameter.parse(val)
				else
					raise Paypal::InvalidParameter, "#{@parameter.class} is an invalid parameter specification"
				end
			end
		end

		class Sequential < Parameter
			include Paypal::Formatters

			attr_accessor :list

			def to_key(symbol)
				return symbol.to_s.split("_", 2).map{|s| s.gsub("_", "") }.join("_").gsub(/[^a-z0-9_]/i, "").upcase
			end

			def initialize(hash = {})
				@list = []
				@schema = hash
				@required = hash.map{|(k,v)| k if v.class != Optional }.compact
			end

			def push(hash)
				raise Paypal::InvalidParameter, "missing required parameter for sequential field" unless (@required - hash.keys).empty?

				hash.each do |k,val|
					type = @schema[k]

					if type.nil?
						hash[k] = val
					elsif type.class == Regexp
						if match = type.match(val)
							hash[k] = match[0]
						else
							raise Paypal::InvalidParameter, "#{val} did not match #{type}"
						end
					elsif [Optional, Enum, Coerce, Default].include?(type.class)
						hash[k] = type.parse(val)
					elsif type.class == Proc && type.call(val)
						hash[k] = val
					elsif type == val.class
						hash[k] = val
					else
						raise Paypal::InvalidParameter, "#{type.class} is an invalid parameter specification"
					end
				end

				@list.push(hash)
			end

			def to_s
				@list.inject(["", 0]) do |(acc, count), item|
					[acc + item.inject("") do |acc2, (k,v)|
						"#{acc2}&#{to_key(k)}#{count}=#{escape_uri_component(item[k])}"
					end, count + 1]
				end
			end

		end

		class Default < Parameter

			def initialize(value, parameter)
				@value = value
				@parameter = parameter
			end

			def parse(val)
				return parameter_parse(val)
			end

		end

		class Coerce < Parameter

			attr_reader :method

			def initialize(method)
				@method = method
			end

			def parse(val)
				return @method.call(val)
			end
		end

		class Enum < Parameter

			# needs to return the exact string if given instead of symbol
			attr_reader :allowed_values

			def initialize(*values)
				@allowed_values = values
			end

			def parse(val)
				if @allowed_values.include?(normalize(val))
					return normalize(val)
				else
					raise Paypal::InvalidParameter, "#{val} was not one of #{@allowed_values}"
				end
			end

			def normalize(val)
				return val if val.class == String
				return Paypal::Api.symbol_to_camel(val) if val.class == Symbol
				return nil
			end
		end

		class Optional < Parameter
			def initialize(parameter = nil)
				@parameter = parameter
			end

			def parse(val)
				return parameter_parse(val)
			end
		end

	end

end