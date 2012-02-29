require "spec_helper"

describe Paypal::MassPayApi do

	describe :mass_pay do
		before(:each) do
			@request = Paypal::MassPayApi.mass_pay
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
				@request.request_string.should include("&L_EMAIL0=mark%40suster.com&L_AMT0=10.23&METHOD=MassPay&CURRENCYCODE=USD&RECEIVERTYPE=EmailAddress")
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

			it "should make a valid request", :slow_paypal => true do
				response = nil
				expect {
					response = @request.make
				}.to_not raise_exception Paypal::InvalidRequest

				response.raw_response.should_not be_nil
				response.success?.should be_true
			end

			describe "with stubbed response" do
				before(:each) do
					Paypal::MassPayRequest.any_instance.stub(:make_request).and_return(Paypal::Response.new("TIMESTAMP=2012%2d02%2d26T23%3a19%3a06Z&CORRELATIONID=204a7348d3e11&ACK=Success&VERSION=84%2e0&BUILD=2571254"))
				end

				before(:each) do
					@response = @request.make
				end

				it "should have a correlationid" do
					@response[:correlation_id].should eq("204a7348d3e11")
					@response.success?.should be_true
				end
			end
		end
	end
end