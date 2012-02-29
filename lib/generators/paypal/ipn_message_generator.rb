require "rails/generators"
require "rails/generators/migration"

module Paypal
	module Generators
		class IpnMessageGenerator < Rails::Generators::Base
			# include Rails::Generators::ResourceHelpers
			include Rails::Generators::Migration

			source_root File.expand_path("../../templates", __FILE__)

			desc "creates a migration to store ipn messages, adds some model helpers, adds a route"

			def create_ipn_message_migration
				migration_template "migration.rb", "db/migrate/add_ipn_messages.rb"
			end

			def self.next_migration_number(path)
			    Time.now.utc.strftime("%Y%m%d%H%M%S")
			end

			def add_to_ipn_message_handling_model
				copy_file "ipn_message.rb", "app/models/ipn_message.rb"
			end

			def add_route
				route %Q{match "ipn_message", :to => "callback_controller#handle_ipn", :as => :ipn_message} if FileTest.exists?("config/routes.rb")
			end

		end
	end
end