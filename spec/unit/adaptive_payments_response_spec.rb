require "spec_helper"

describe Paypal::AdaptivePaymentsResponse do
	describe "for pay requests" do
		before(:each) do
			@response = Paypal::AdaptivePaymentsResponse.new("responseEnvelope.timestamp=2012-02-29T13%3A40%3A17.074-08%3A00&responseEnvelope.ack=Success&responseEnvelope.correlationId=722689b427b7c&responseEnvelope.build=2486531&payKey=AP-1W763567RM6393227&paymentExecStatus=CREATED")
		end

		describe "embedded url" do
			it "should create a proper embedded url" do
				@response.embedded_url.should include("/webapps/adaptivepayment/flow/pay?payKey=")
			end
		end

		describe "redirect url" do
			it "should create a proper redirect url" do
				@response.redirect_url.should include("/webscr?cmd=_ap-")
			end
		end

		it "should know about production vs sandbox" do
			Paypal::Request.environment = "production"
			@response.redirect_url.should_not include("sandbox")
			Paypal::Request.environment = "something else"
			@response.redirect_url.should include("sandbox")
		end
	end

	describe "for payapproval requests" do
		it "should create a proper redirect url" do

		end
	end

end