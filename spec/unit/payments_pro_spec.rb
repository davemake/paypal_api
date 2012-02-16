require "spec_helper"

describe Paypal::PaymentsPro do
	describe :do_direct_payment do
		before do
			@request = Paypal::PaymentsPro.do_direct_payment
			@request.ip_address = "192.168.0.1"
			@request.exp_date = "042013"
			@request.cvv2 = "123"
			@request.acct = "4683075410516684"
		end

		it "should fail without enough params" do
			expect {
				@request.make
			}.to raise_exception Paypal::InvalidRequest
		end

		context "with more params" do
			before do
				@request.first_name = "mark"
				@request.last_name = "suster"
				@request.street = "12 thirteen lane"
				@request.city = "brooklyn"
				@request.state = "ny"
				@request.zip = "11211"
				@request.amt = 1.00
			end

			it "should formulate a valid request" do
				@request.request_string.should_not be_nil

				expect {
					URI.parse(@request.request_string)
				}.to_not raise_exception
			end

			it "should make a valid request", :slow_paypal => true do
				response = nil
				expect {
					response = @request.make
				}.to_not raise_exception Paypal::InvalidRequest

				response.raw_response.should_not be_nil
				response.success?.should be_true
			end

			context "with stubbed response" do
				before do
					Paypal::DoDirectPaymentRequest.any_instance.stub(:make_request).and_return(Paypal::Response.new("TIMESTAMP=2012%2d02%2d16T04%3a59%3a39Z&CORRELATIONID=4b356d90312b7&ACK=Success&VERSION=76&BUILD=2571254&AMT=1%2e00&CURRENCYCODE=USD&AVSCODE=X&CVV2MATCH=M&TRANSACTIONID=9WU7637669251764V"))
				end

				before(:each) do
					@response = @request.make
				end

				it "should have a correlationid" do
					@response[:correlation_id].should_not be_nil
				end
			end
		end
	end

	describe :do_reference_transaction do
		before do
			@request = Paypal::PaymentsPro.do_reference_transaction
			# @request.ip_address = "192.168.0.1"
		end

		it "should fail without enough params" do
			expect {
				@request.make
			}.to raise_exception Paypal::InvalidRequest
		end

		context "with more params" do
			before do
				@request.reference_id = "9WU7637669251764V"
				# @request.first_name = "mark"
				# @request.last_name = "suster"
				# @request.street = "12 thirteen lane"
				# @request.city = "brooklyn"
				# @request.state = "ny"
				# @request.zip = "11211"
				@request.amt = 1.00
			end

			it "should formulate a valid request" do
				@request.request_string.should_not be_nil

				expect {
					URI.parse(@request.request_string)
				}.to_not raise_exception
			end

			it "should make a valid request", :slow_paypal => true do
				response = nil
				expect {
					response = @request.make
				}.to_not raise_exception Paypal::InvalidRequest

				response.raw_response.should_not be_nil
				response.success?.should be_true
			end

			context "with stubbed response" do
				before do
					Paypal::DoReferenceTransactionRequest.any_instance.stub(:make_request).and_return(Paypal::Response.new("AVSCODE=X&CVV2MATCH=M&TIMESTAMP=2012%2d02%2d16T05%3a32%3a16Z&CORRELATIONID=276e70e08049c&ACK=Success&VERSION=84%2e00&BUILD=2571254&TRANSACTIONID=31R0686475644053G&AMT=1%2e00&CURRENCYCODE=USD"))
				end

				before(:each) do
					@response = @request.make
				end

				it "should have a correlationid" do
					@response[:correlation_id].should_not be_nil
				end
			end
		end
	end
end