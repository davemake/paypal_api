require "rails/generators"
require "rails/generators/migration"

module Paypal
	module Generators
		class IpnMessageGenerator < Rails::Generators::Base
			include Rails::Generators::ResourceHelpers
			# include Rails::

			namespace "paypal"

			source_root File.expand_path("../templates", __FILE__)

			desc "creates a migration to store ipn messages, adds some model helpers"

			def create_ipn_message_migration
				generate("model", "ipn_message message:text correlation_id:string transaction_id:string tracking_id:string success:boolean")
			end

			def add_to_ipn_message_handling_model
				copy_file "ipn_message.rb", "app/models/ipn_message.rb"
			end

		end
	end
end