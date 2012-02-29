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

	def unique_ids
		hash = YAML.load(self.body)


	end

end