require "spec_helper"

describe Paypal::AdaptivePayments do

	describe :to_key do
		it "should camel but not first letter" do
			string = Paypal::AdaptivePayments.to_key(:som_symbole_here)
			string.should eq("somSymboleHere")
		end
	end

	describe :pay do
		before(:each) do
			@request = Paypal::AdaptivePayments.pay
		end

		it "should be a PayRequest" do
			@request.should be_a(Paypal::PayRequest)
		end

		it "should be invalid without a lot of stuff" do
			@request.valid?.should be_false
			@request.error_message.should_not be_nil
		end

		context "with some information filled in" do
			before(:each) do
				@request.receiver.push({
					:email => "test@dude.com",
					:amount => 10.22
				})
				@request.cancel_url = "http://www.test.com/cancel"
				@request.return_url = "http://www.test.com/return"
			end

			shared_examples_for "a good pay request" do
				it "should look like a successful request" do
					@request.request_string.should include("https://api-3t.sandbox.paypal.com/nvp?PWD=&USER=&SIGNATURE=&VERSION=84.0&receiverList.receiver(0).email=test%40dude.com&receiverList.receiver(0).amount=10.22&actionType=")
					@request.request_string.should include("&currencyCode=USD&cancelUrl=http%3A%2F%2Fwww.test.com%2Fcancel&returnUrl=http%3A%2F%2Fwww.test.com%2Freturn&requestEnvelope.errorLanguage=en_US&requestEnvelope.detailLevel=ReturnAll")
				end

				it "should not raise exception, response should be success" do
					expect {
						@request.make
						@request.raw_response.should be_nil
					}.to_not raise_exception(Paypal::InvalidRequest)
				end
			end

			describe "when creating" do
				before(:each) do
					@request.action_type = :create
				end

				it_behaves_like "a good pay request"
			end

			describe "when paying" do
				before(:each) do
					@request.action_type = :pay
				end

				it_behaves_like "a good pay request"
			end
		end
	end
end