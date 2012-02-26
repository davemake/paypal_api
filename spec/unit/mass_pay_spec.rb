require "spec_helper"

describe Paypal::MassPay do

	describe :mass_pay do
		before(:each) do
			@request = Paypal::MassPay.mass_pay
		end

		it "should be invalid without a payee" do
			@request.valid?.should be_false
			@request.error_message.should_not be_nil
		end

		context "with payees" do

			before(:each) do
				@request.payee.push({
						:email => "mark@suster.com",
						:amt => 10.23
					})
			end

			it "should be valid with a payee" do
				@request.valid?.should be_true
				@request.error_message.should be_nil
			end

			it "should render the keys in the request properly" do
				@request.request_string.should eq("https://api-3t.sandbox.paypal.com/nvp?PWD=&USER=&SIGNATURE=&VERSION=84.0&L_EMAIL0=mark%40suster.com&L_AMT0=10.231&METHOD=MassPay&CURRENCYCODE=USD&RECEIVERTYPE=EmailAddress")
				expect {
					URI.parse(@request.request_string)
				}.to_not raise_exception
			end

			it "should allow 249 more payees" do
				249.times do
					@request.payee.push({
							:email => "mark@suster.com",
							:amt => 10.23
						})
				end

				@request.valid?.should be_true
			end

			it "should error out when there are more than 250 payees" do
				expect {
					250.times do
						@request.payee.push({
								:email => "mark@suster.com",
								:amt => 10.23
							})
					end
				}.to raise_exception(Paypal::InvalidParameter)
			end

			it "should make a valid request" do
				response = nil
				expect {
					response = @request.make
				}.to_not raise_exception Paypal::InvalidRequest

				response.raw_response.should be_nil
				response.success?.should be_true
			end

			describe "when making the request" do

			end
		end
	end
end