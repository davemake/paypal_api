require "spec_helper"

describe Paypal::AdaptivePayments do

	before :all do
		Paypal::Request.application_id = "APP-80W284485P519543T"
	end

	describe :to_key do
		it "should camel but not first letter" do
			string = Paypal::AdaptivePaymentsRequest.new.to_key(:som_symbole_here)
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
				@request.ip_address = "168.212.226.204"
			end

			shared_examples_for "a good pay request" do
				it "should look like a successful request" do
					@request.request_string.should include("&receiverList.receiver(0).email=test%40dude.com&receiverList.receiver(0).amount=10.22&actionType=")
					@request.request_string.should include("&currencyCode=USD&cancelUrl=http%3A%2F%2Fwww.test.com%2Fcancel&returnUrl=http%3A%2F%2Fwww.test.com%2Freturn&requestEnvelope.errorLanguage=en_US&requestEnvelope.detailLevel=ReturnAll")
				end

				it "should not raise exception, response should be success" do
					Paypal::PayRequest.any_instance.stub(:make_request).and_return("")
					expect {
						response = @request.make
					}.to_not raise_exception(Paypal::InvalidRequest)
				end

				it "should get a response from paypal", :slow_paypal => true do
					# @request.test_request = true
					response = @request.make
					response.success?.should be_true
				end

				describe "with stubbed response" do
					before(:each) do
						Paypal::PayRequest.any_instance.stub(:make_request).and_return(Paypal::AdaptivePaymentsResponse.new("responseEnvelope.timestamp=2012-02-29T13%3A40%3A17.074-08%3A00&responseEnvelope.ack=Success&responseEnvelope.correlationId=722689b427b7c&responseEnvelope.build=2486531&payKey=AP-1W763567RM6393227&paymentExecStatus=CREATED"))
						@response = @request.make
					end

					it "should be an adative payments response" do
						@response.should be_a(Paypal::AdaptivePaymentsResponse)
					end

					it "should have a correlation_id" do
						@response[:correlation_id].should eq("722689b427b7c")
					end

					it "should have a pay key and exec status" do
						@response[:pay_key].should eq("AP-1W763567RM6393227")
						@response[:payment_exec_status].should eq("CREATED")
					end
				end

				describe "with stubbed failure" do
					before(:each) do
						Paypal::PayRequest.any_instance.stub(:make_request).and_return(Paypal::AdaptivePaymentsResponse.new("responseEnvelope.timestamp=2012-02-29T13%3A35%3A28.528-08%3A00&responseEnvelope.ack=Failure&responseEnvelope.correlationId=ca0befbd1fe0b&responseEnvelope.build=2486531&error(0).errorId=560022&error(0).domain=PLATFORM&error(0).subdomain=Application&error(0).severity=Error&error(0).category=Application&error(0).message=The+X-PAYPAL-APPLICATION-ID+header+contains+an+invalid+value&error(0).parameter(0)=X-PAYPAL-APPLICATION-ID"))
						@response = @request.make
					end

					it "should have a correlation id" do
						@response[:correlation_id].should eq("ca0befbd1fe0b")
					end

					it "should have an error message" do
						@response.error_message.should_not be_nil
					end

					it "should not be success" do
						@response.success?.should be_false
					end

					it "should have an error field and code" do
						@response.error_code.should eq("560022")
						@response.error_field.should eq("X-PAYPAL-APPLICATION-ID")
					end
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