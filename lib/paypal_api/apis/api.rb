module Paypal
	module Formatters
		def escape_uri_component(string)
			string = string.to_s
			return URI.escape(string, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
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
						instance_variable_set(variable, v.clone) unless instance_variable_defined?(variable)
						instance_variable_get(variable)
					end
				end
			end

			# collected from set request signature
			def self.set_required(klass, keys)
				klass.class_eval do
					@required = keys
				end
			end

			# collected from set request signature
			def self.set_sequential(klass, keys)
				klass.class_eval do
					@sequential = keys
				end
			end

			def self.symbol_to_camel(symbol)
				return symbol.to_s.downcase.split("_").map(&:capitalize).join
			end

			def self.symbol_to_lower_camel(symbol)
				cameled = symbol_to_camel(symbol)
				return cameled[0].downcase + cameled.split(/./, 2).join
			end

			def self.set_request_signature(name, hash)

				# create Request subclass if not already created
				subname = self.to_s.split("::")[1]
				if !Paypal.const_defined?("#{subname}Request")
					Paypal.class_eval <<-EOS
						class #{subname}Request < Request
							def self.parent_api
								return #{self}
							end
						end
					EOS
				end

				# create request object
				class_name = "#{self.symbol_to_camel name}Request"
				Paypal.class_eval <<-EOS
				  class #{class_name} < #{subname}Request
				  	def self.api_method
				  		return "#{name}"
				  	end
				  end
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

			# hack for no Bool class :'(
			def self.bool_class
				return Enum.new("true", "false")
			end

			# TODO: make this useful :'(
			# def set_response_signature(hash)
			# 	hash.each do |k,v|
			# 		set_reader k, v
			# 	end
			# end
	end

end