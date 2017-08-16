require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'

  #add_group 'Lib', 'lib/'
end

require "bundler/setup"
require "pp-adaptive"
require "pry"

Pathname.glob(File.join(File.dirname(__FILE__), "**/shared/**/*.rb")).each do |file|
  require file
end

def set_up_client(sandbox=false, mobile=false)
  @client = AdaptivePayments::Client.new(
    sandbox: (sandbox ? true : false ),
    checkout_type: (mobile ? "mobile" : "desktop")
  )
  return @client
end

def set_up_mock_response
  @response = AdaptivePayments::ExecutePaymentRequest.new(
    :action_type     => "PAY",
    :pay_key         => "ABCD-1234",
    :funding_plan_id => "funding123"
  )
  return @response
end
