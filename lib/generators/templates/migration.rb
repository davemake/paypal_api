class CreateIpnMessages < ActiveRecord::Migration
	def change
		create_table :ipn_messages do |t|
			t.text :message
			t.string :correlation_id
			t.string :transaction_id
			t.string :tracking_id
			t.boolean :success

			t.timestamps
		end
	end
end