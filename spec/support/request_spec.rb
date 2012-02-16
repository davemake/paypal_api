require "spec_helper"

describe Paypal::Request do

	it "should create a well formed url" do
		request = Paypal::Request.new

		url = request.paypal_endpoint_with_defaults
		URI.parse(url)
	end

	context "when making requests" do
		before do
			@api = Paypal::Api

			class Test < @api
				set_request_signature :tester, {
					:test_field => "something",
					:optional => @api::Optional.new(String),
					:string => String,
					:fixnum => Fixnum,
					:default => @api::Default.new("tamp", Fixnum),
					:enum => @api::Enum.new("One", "Two"),
					:sequential => @api::Sequential.new({:l_string => String, :l_fixnum => Fixnum, :l_set_category => Optional.new(String)})
				}
			end

			@request = Test.tester({
				:string => "adsafasdf",
				:fixnum => 23,
				:enum => :one
			})

			@request.sequential.push({:l_string => "tamp", :l_fixnum => 2323})

			@string = @request.request_string
		end

		it "should create a request string with params" do
			@string.should include("TESTFIELD")
			@string.should include("something")
			@string.should include("adsafasdf")
			@string.should_not include("OPTIONAL")
			@string.should include("ENUM=One")
		end

		it "should add userpass and secret fields" do
			@string.should include("PWD")
			@string.should include("USER")
			@string.should include("SIGNATURE")
			@string.should include("VERSION")
		end

		it "should use a paypal endpoint" do
			@string.should include(Paypal::Request::PAYPAL_ENDPOINT)
		end

		it "should have required keys set" do
			@request.class.required_keys.should eq([:test_field, :string, :fixnum, :default, :enum])
		end

		it "should include sequential stuff in the request string" do
			@string.should include("L_STRING0")
			@string.should include("L_FIXNUM0")
		end

		it "should return a well formed url" do
			parsed = nil
			expect {
				parsed = URI.parse(@string)
			}.to_not raise_exception

			parsed.query.should include("TESTFIELD")
			parsed.query.should include("L_STRING0")

			hash = nil
			expect {
				hash = CGI.parse parsed.query
			}.to_not raise_exception

			hash.keys.should include("L_STRING0")
		end

		it "should look for a config file if we're in rails"
	end
end