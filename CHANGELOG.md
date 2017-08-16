# Change Log
All notable changes in this gem will be documented here.
This project aspires to follow [semantic versioning](http://semver.org).


## 1.2.0 - 2017-08-16
### Changed
- :express_handshake ("SetExpressCheckout") method:
  1. can now receive allcaps options keys and use them directly in communicaton with paypal. Useful for passing custom options like "LOCALECODE" => "LV"
  2. can now receive "VERBOSE" => true option key-value pair to be verbose about processing done.

## 1.1.1 - 2016-05-05
### Added
- :receiver_email interpretation in PAYMENTREQUEST_0_SELLERPAYPALACCOUNTID for mobile express checkouts

## 1.1.0 - 2016-03-03
### Added
- Support for mobile responsive express checkout via option and new methods on Client
- "pry" gem in dev dependencies, so one can `binding.pry`

## 1.0.0 - 2014-10-31
### Added
- Core funcionality
