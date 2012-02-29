require "spec_helper"

describe Paypal::Request do

	it "should create a well formed url" do
		request = Paypal::Request.new

		url = request.paypal_endpoint_with_defaults
		URI.parse(url)
	end

	it "should allow you to set the environment" do
		Paypal::Request.environment = "production"

		Paypal::Request.new
		Paypal::Request.class_variable_get("@@paypal_endpoint").should eq("https://api-3t.paypal.com/nvp")

		Paypal::Request.environment = "development"

		Paypal::Request.new
		Paypal::Request.class_variable_get("@@paypal_endpoint").should eq("https://api-3t.sandbox.paypal.com/nvp")
	end

	it "should allow you to set the user pwd and signature" do
		Paypal::Request.user = "asdf"
		Paypal::Request.pwd = "zxcv"
		Paypal::Request.signature = ";lkj"

		request = Paypal::Request.new
		request.request_string.should include("USER=asdf")
		request.request_string.should include("PWD=zxcv")
		request.request_string.should include("SIGNATURE=;lkj")
	end

	it "should allow you to set the version" do
		Paypal::Request.version = "76.0"

		request = Paypal::Request.new
		request.request_string.should include("VERSION=76.0")
	end

	describe "should look for a config file if we're in rails" do

		describe "for production" do
			before do
				Module.should_receive(:const_defined?).and_return(true)
				Module.should_receive(:const_get).and_return(stub(:root => true))

				Paypal::Request.any_instance.should_receive(:get_info).and_return({"environment" => "production" })
			end

			it "should use the real server" do
				Paypal::Request.new
				Paypal::Request.class_variable_get("@@paypal_endpoint").should eq("https://api-3t.paypal.com/nvp")
			end
		end

		describe "for anything else" do
			before do
				Paypal::Request.any_instance.stub(:get_info).and_return({
							"production" => { "environment" => "development" }
						})
			end

			it "should use the sandbox server" do
				Paypal::Request.new
				Paypal::Request.class_variable_get("@@paypal_endpoint").should eq("https://api-3t.sandbox.paypal.com/nvp")
			end
		end
	end

	context "when making requests" do
		before do
			@api = Paypal::Api

			class Testical < @api
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

			@request = Testical.tester({
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
			@string.should include(".paypal.com/nvp")
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
	end
end