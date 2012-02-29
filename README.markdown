# Paypal Api Gem

a ruby library to handle the entire paypal api.

paypals documentation sucks, and there do not appear to be any officially supported paypal gems.
the gems that do exist do not cover the entire api.

# Usage

## Interfacing with the gem:
```ruby
require "paypal_api"

request = Paypal::PaymentsPro.do_direct_payment # returns instance of Paypal::DoDirectPaymentRequest

# Set required fields
request.first_name = "mark"
request.last_name = "winton"
request.amt = 10.00

# Add a list type field
request.item.push {
	:email => "bro@dudeman.com",
	:amt => 23.0
}

response = request.make

response.success? # true if successful

response[:correlation_id] # correlation id string returned by paypal
response[:transaction_id] # transaction id string, not return on all calls
```

## Configure

```ruby
Paypal::Request.version = "84.0"
Paypal::Request.environment = "development" # or "production"
Paypal::Request.user = "user_api1.something.com"
Paypal::Request.pwd = "some_password_they_gave_you"
Paypal::Request.signature = "some_signature"
```

paypal api credentials for production can be found here: [https://www.paypal.com/us/cgi-bin/webscr?cmd=_profile-api-signature](https://www.paypal.com/us/cgi-bin/webscr?cmd=_profile-api-signature)

sandbox credentials can be found here: [https://developer.paypal.com/cgi-bin/devscr?cmd=_certs-session&login_access=0](https://developer.paypal.com/cgi-bin/devscr?cmd=_certs-session&login_access=0)

## Rails

if you'd like to have multi environment configuration in rails, place a file at `config/paypal.yml` and the gem will read from it accordingly

```yml
test:
  environment: "sandbox"
  username: "user_api1.something.com"
  password: "some_password_they_gave_you"
  signature: "some_signature"
  application_id: "APP-80W284485P519543T" # only necessary for adaptive payments api

production:
  environment: "production"
  username: <%= ENV["PAYPAL_USERNAME"] %>
  password: <%= ENV["PAYPAL_PASSWORD"] %>
  signature: <%= ENV["PAYPAL_SIGNATURE"] %>
  application_id <%= ENV["PAYPAL_APP_ID"] %>
```

## Ipn Messages

there is an ipn message model generator: `rails generate paypal:ipn_message`, it will create
a migration and the IpnMessage model.

you must edit the route and add a handler like so:

```ruby
# config/routes
MyApp::Application.routes.draw do

  match '/ipn_message', to: 'handlers#handle_ipn', as: 'ipn_message'

end

# app/controllers/handlers_controller.rb
class HandlersController < ApplicationController

  def handle_ipn
    @ipn_message = IpnMessage.create_from_message(params) # provided by generator

    @ipn_message.success?
    @ipn_message.correlation_id
    @ipn_message.transaction_id # not always provided
    @ipn_message.message # raw text of the message
  end

end
```

## Testing

i'm an rspec kinda guy. note that i have test for actual requests against the paypal
sandbox server, but they are off by default. remove the line about `:slow_paypal` in
`spec/spec_helper.rb` to turn these back on.

also note that, for the Adaptive Payments api, an application id is required, for testing,
you can use this: "APP-80W284485P519543T" ([https://cms.paypal.com/us/cgi-bin/?cmd=_render-content&content_ID=developer/e_howto_api_APGettingStarted](https://cms.paypal.com/us/cgi-bin/?cmd=_render-content&content_ID=developer/e_howto_api_APGettingStarted))

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

for contributing to the api method request specs, look at `lib/paypal_api/apis/payments_pro.rb`

this is my first gem, so i'll be excited for any contributions :'(

# Paypal API Checklist

here's a list of api methods, and whether or not they are implemented (please take a look at `lib/paypal_api/apis/payments_pro.rb` if you'd
like to contribute, i've made it pretty easy to add compatibility for a new api call)

## Payments Pro

note that paypal has a strict policy about who they approve for
payments pro. you can sign up for it, and start testing it, but as soon as your first
real charge goes through, they will vet your website and many people have gotten burned
by this (including me, sad sad me...).

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

note that you need to request that paypal enable mass pay for your account before it will work

* mass_pay - &#10003;

## Instant Pay Notifications

## Express Checkout

## Adaptive Payments

this api is very different from the others... getting it to work with the way i built things already
required some ugly stuff, but it helps keep the gem consistent from the outside.

* pay - &#10003;

## Adaptive Accounts

## Invoicing

## Button Manager

## Permissions
