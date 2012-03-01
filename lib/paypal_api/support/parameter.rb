
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
						raise Paypal::InvalidParameter, "'#{val}'' is not of type #{@parameter.class}"
					end
				elsif @parameter.class == Regexp
					match = @parameter.match(val)
					if match
						return match[0]
					else
						raise Paypal::InvalidParameter, "'#{val}' does not match #{@parameter}"
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

			# allows you to specify an optional key -> paypal_key proc due to nonstandard key formatting
			def initialize(hash = {}, limit = nil, key_proc = nil)
				@list = []
				@schema = hash
				@required = hash.map{|(k,v)| k if v.class != Optional }.compact
				@key_proc = key_proc if key_proc
				@limit = limit
			end

			# necessary because sequential stores request state, need a new list created for each
			# 	request instance
			def clone
				return self.class.new(@schema, @limit, @key_proc)
			end

			def length
				return @list.length
			end

			def push(hash)
				raise Paypal::InvalidParameter, "missing required parameter for sequential field" unless (@required - hash.keys).empty?
				raise Paypal::InvalidParameter, "field cannot have more than #{@limit} items, #{@list.length} provided" if !@limit.nil? && @list.length == @limit

				hash.each do |k,val|
					type = @schema[k]

					if type.nil?
						hash[k] = val
					elsif type.class == Regexp
						if match = type.match(val)
							hash[k] = match[0]
						else
							raise Paypal::InvalidParameter, "'#{val}' did not match #{type}"
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

			def to_key(symbol, i)
				if @key_proc
					return @key_proc.call(symbol, i)
				else
					return symbol.to_s.split("_", 2).map{|s| s.gsub("_", "") }.join("_").gsub(/[^a-z0-9_]/i, "").upcase + "#{i}"
				end
			end

			def to_query_string
				output = ""
				@list.each_index do |i|
					@list[i].each do |(k,v)|
						output = "#{output}&#{to_key(k, i)}=#{escape_uri_component(@list[i][k])}"
					end
				end
				return output
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
				if values.length == 1 && values[0].is_a?(::Hash)
					@hash_enum = true
					@allowed_values = values[0]
				else
					@allowed_values = values
					@normalized_values = @allowed_values.inject({}){|acc, v| acc[normalize(v)] = v; acc}
				end
			end

			def parse(val)
				if @hash_enum
					if @allowed_values.include?(val)
						return @allowed_values[val]
					else
						raise Paypal::InvalidParameter, "'#{val}' must be a key in #{@allowed_values.keys}"
					end
				else
					normed = normalize(val)
					if @normalized_values.include?(normed)
						return @normalized_values[normed]
					else
						raise Paypal::InvalidParameter, "'#{val}' must be one of #{@allowed_values}"
					end
				end
			end

			def normalize(val)
				return val.to_s.downcase.gsub(/[^a-z0-9]/,"")
			end
		end

		class Hash < Parameter

		end

		# Optional and Default can take other parameters as input

		class Optional < Parameter
			def initialize(parameter = nil)
				@parameter = parameter.is_a?(Sequential) ? parameter.clone : parameter
			end

			def parse(val)
				return parameter_parse(val)
			end
		end


		class Default < Parameter

			def initialize(value, parameter)
				@value = value
				@parameter = parameter.is_a?(Sequential) ? parameter.clone : parameter
			end

			def parse(val)
				return parameter_parse(val)
			end

		end

	end

end