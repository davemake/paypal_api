# Paypal Api Gem

a ruby library to handle the entire paypal api.

paypals documentation sucks, and there do not appear to be any officially supported paypal gems.
the gems that do exist do not cover the entire api.

# Goal

the goal is to organize interaction with paypals api into a standard. anyone who has looked at their documentation will notice
it is not standardized in any way. the main effort i am pushing for is to have a nice DSL for specifying the various api
methods and their associated spec.

# Usage

for interfacing with the gem:

	require "paypal_api"

	request = Paypal::PaymentsPro.do_direct_payment # returns instance of Paypal::DoDirectPaymentRequest

	# set required fields
	request.first_name = "mark"
	request.last_name = "winton"
	request.amt = 10.00

	# add a list type field
	request.item.push {
		:l_email => "bro@dudeman.com",
		:l_amt => 23.0
	}

	response = request.make

	response.success?

for writing the api method request specs, look at lib/paypal_api/apis/payments_pro.rb

# Current Status

alpha

the work i've done so far is in order to get up and running on a project. once the project is settled, i'll be spending
some more time making the gem complete. once i feel it is in the beta stage i will push it to the official ruby gems
repository. in order to get to that stage, i will need to add support for adaptive payments, express checkout, etc...

# How To Contribute

right now the most help i could use is in writing the specs for the various api calls from the Payments Pro api. i will be working on
separating out the different access methods shortly (there's a huge difference between how to call the Payments Pro api vs the Adaptive Payments api).

as this is my first gem, i could also use help with some of the niceties with rails. ideally there will be a generator for migrating your db
to store ipn messages, and a generated class with callbacks to handle the various cases. this will probably take a lot of effort since there
are many intricacies in the meanings of the different ipn's.

this is my first gem, so i'll be excited for any contributions :'(

# Paypal API Checklist

here's a list of api methods, and whether or not they are implemented (please take a look at lib/paypal_api/apis/payments_pro.rb if you'd
like to contribute, i've made it pretty easy to add compatibility for a new api call)

## Payments Pro

* do_direct_payment - &#10003;

* do_reference_transaction - &#10003;

* do_capture - &#10003;

* do_void - &#10003;

* get_recurring_payments_profile_details - started

* address_verify

* bill_outstanding_amount

* callback

* create_recurring_payments_profile

* do_authorization

* do_express_checkout_payment

* do_nonreferenced_credit

* do_reauthorization

* get_balance

* get_billing_agreement_customer_details

* get_express_checkout_details

* get_transaction_details

* manage_pending_transaction_status

* manage_recurring_payments_profile_status

* refund_transaction

* set_customer_billing_agreement

* set_express_checkout

* transaction_search

* update_recurring_payments_profile

## Mass Pay

* mass_pay - &#10003;

## Instant Pay Notifications

## Express Checkout

## Adaptive Payments

## Adaptive Accounts

## Invoicing

## Button Manager

## Permissions
