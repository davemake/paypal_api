require "rails/all"
require "spec_helper"
require "generator_spec/test_case"

describe Paypal::Generators::IpnMessageGenerator do
  include GeneratorSpec::TestCase
  destination File.expand_path("../../tmp", __FILE__)

  before(:all) do
    prepare_destination
    run_generator
  end

  it "should have file" do
    assert_file "app/models/ipn_message.rb"
  end

  specify do
    destination_root.should have_structure {
      no_file "test.rb"
      directory "app" do
        directory "models" do
          file "ipn_message.rb" do
            contains "def create_from_message"
            contains "def unique_ids"
          end
        end
      end
      directory "db" do
        directory "migrate" do
          file "create_ipn_messages.rb"
          migration "create_ipn_messages" do
            contains "class IpnMessageMigration"
            contains ":message"
            contains ":correlation_id"
            contains ":transaction_id"
            contains ":success"
          end
        end
      end
    }
  end
end