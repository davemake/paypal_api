# Paypal Api Gem

a ruby library to handle the entire paypal api.

paypals documentation sucks, and there do not appear to be any officially supported paypal gems.
the gems that do exist do not cover the entire api.

# Usage

i want interaction with the gem to be flat and straight-forward, with clear mapping between the api docs and the gem. right now
the only place where i break this is for "list type" fields, where it makes sense to treat it more like a ruby array.
all keys are ruby style (snake_case), and should automatically get converted to the proper formatting for you.

if you don't add all the required fields to the request, it will raise `Paypal::InvalidRequest` exceptions. if you try to set the wrong
type to a field, it will raise `Paypal::InvalidParameter` exceptions.

### Payments Pro Example

the most useful methods, imo, are do_direct_payment, do_reference_

```ruby
require "paypal_api"

# create request
request = Paypal::PaymentsPro.do_reference_transaction # returns instance of Paypal::DoDirectPaymentRequest

# set required fields
request.reference_id = "other_paypal_transaction_id"
request.payment_action = :authorization
request.amt = 10.00

# make request
response = request.make

# usable information
response.success? # true if successful
response[:correlation_id] # correlation id string returned by paypal
transaction_id = response[:transaction_id] # transaction id string, not return on all calls

# in this example, since the first request was an authorization, you can then capture it
request2 = Paypal::PaymentsPro.do_capture # returns instance of Paypal::DoCaptureRequest

request2.authorization_id = transaction_id
request2.amt = 10.00

response2 = request2.make

response2.success?
```

### Adaptive Payments Example

even though the api's are very different, they should be abstracted the same way

```ruby
require "paypal_api"

request = Paypal::AdaptivePayments.pay # returns instance of Paypal::PayRequest

# set required fields
request.cancel_url = "http://www.test.com/cancel"
request.return_url = "http://www.test.com/return"
request.ip_address = "192.168.1.1"

# add a list type field
request.receiver.push {
  :email => "bro@dudeman.com",
  :amount => 23.0
}

# make request
response = request.make

# usable information
response.success? # true if successful
response[:pay_key] # usually what you use this api method for

# errors
response.error_message # populated by paypal response error when request fails
response.error_code # populated by paypal response error
response.error_field # some api calls let you know which field caused the issue
```

### More

the actual api method definitions should be more or less readable as is (if not, you can call me a jerk, i sorry). look in
`lib/paypal_api/apis/` for reference, until i document each method.

## Configure

it's hard to navigate paypals terribly organized everything, here are some links to help you find what you need:

paypal api credentials for production: [https://www.paypal.com/us/cgi-bin/webscr?cmd=_profile-api-signature](https://www.paypal.com/us/cgi-bin/webscr?cmd=_profile-api-signature)
sandbox credentials: [https://developer.paypal.com/cgi-bin/devscr?cmd=_certs-session&login_access=0](https://developer.paypal.com/cgi-bin/devscr?cmd=_certs-session&login_access=0)
where to tell paypal what your ipn callback url is: [https://www.paypal.com/cgi-bin/customerprofileweb?cmd=_profile-ipn-notify](https://www.paypal.com/cgi-bin/customerprofileweb?cmd=_profile-ipn-notify)

### Simple Configuration

```ruby
Paypal::Request.version = "84.0"
Paypal::Request.environment = "development" # or "production"
Paypal::Request.user = "user_api1.something.com"
Paypal::Request.pwd = "some_password_they_gave_you"
Paypal::Request.signature = "some_signature"
```

### Configure For Rails

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

there is an ipn message model generator: `$ rails generate paypal:ipn_message`, it will create
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

you can run the tests: `$ bundle exec rspec spec`

i'm an rspec kinda guy, hopefully you are ok with that. note that i have tests for actual requests against the paypal
sandbox server, but they are turned off by default. remove the line about `:slow_paypal` in
`spec/spec_helper.rb` to turn these back on.

also note that, for the Adaptive Payments api, an application id is required, for testing,
you can use this: "APP-80W284485P519543T" ([https://cms.paypal.com/us/cgi-bin/?cmd=_render-content&content_ID=developer/e_howto_api_APGettingStarted](https://cms.paypal.com/us/cgi-bin/?cmd=_render-content&content_ID=developer/e_howto_api_APGettingStarted))

# Current Status

alpha

the work i've done so far is in order to get up and running on a project. once the project is settled, i'll be spending
some more time making the gem complete. once i feel it is in the beta stage i will push it to the official ruby gems
repository. in order to get to that stage, i will need to add support for adaptive payments, express checkout, etc...

# How To Contribute

right now the most help i could use is in writing the signatures for the various api calls from the Payments Pro and Adaptive Payments apis (or any others).

i've tried to make it pretty easy to contribute, signatures are created pretty easily:

```ruby
# lib/paypal_api/apis/payments_pro.rb

module Paypal
  class PaymentsPro < Paypal::Api

    set_request_signature :do_capture, {
      :method => "DoCapture",
      :authorization_id => String,
      :amt => Float,
      :currency_code => Default.new("USD", /^[a-z]{3}$/i),
      :complete_type => Default.new("Complete", Enum.new("Complete", "NotComplete")),
      :inv_num => Optional.new(String),
      :note => Optional.new(String),
      :soft_descriptor => Optional.new(lambda {|val|
        if val.match(/^([a-z0-9]|\.|-|\*| )*$/i) && val.length <= 22
          return true
        else
          return false
        end
      }),

      :store_id => Optional.new(String),
      :terminal_id => Optional.new(String)
    }

  end
end
```

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
