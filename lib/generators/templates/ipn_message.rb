class IpnMessage < ActiveRecord::Base

	alias_method :success?, :success

	def self.create_from_message(hash)
		ipn_message = IpnMessage.new

		ipn_message.body = hash.to_yaml
		ipn_message.success = hash["ACK"] == "Success"
		ipn_message.correlation_id = hash["correlation_id"]
		ipn_message.transaction_id = hash["transaction_id"]

		ipn_message.save
		return ipn_message
	end

	# returns hash of unique_id:string => status:bool
	def unique_ids
		hash = YAML.load(self.body)

		return hash.inject({}){|acc, (k,v)|
			k.to_s =~ /unique_id_(\d+)/
			acc[v] = hash["status_#{$1}"] == "Completed" if $1
			acc
		}
	end

end