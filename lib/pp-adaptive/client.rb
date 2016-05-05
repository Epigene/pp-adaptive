require "rest-client"
require "virtus"

module AdaptivePayments
  # The principle hub through which all requests and responses are passed.
  class Client
    include Virtus.model

    attribute :user_id,   String, :header => "X-PAYPAL-SECURITY-USERID"
    attribute :password,  String, :header => "X-PAYPAL-SECURITY-PASSWORD"
    attribute :signature, String, :header => "X-PAYPAL-SECURITY-SIGNATURE"
    attribute :app_id,    String, :header => "X-PAYPAL-APPLICATION-ID"
    attribute :device_ip, String, :header => "X-PAYPAL-DEVICE-IPADDRESS"

    attribute :checkout_type, String, :default => "desktop"

    # Initialize the client with the given options.
    #
    # Options can also be passed via the accessors, if prefered.
    #
    # @option [String] user_id
    #   the adaptive payments API user id
    #
    # @option [String] password
    #   the adaptive payments API password
    #
    # @option [String] signature
    #   the adaptive payments API signature
    #
    # @option [String] app_id
    #   the app ID given to use adaptive payments
    #
    # @option [String] device_ip
    #   the IP address of the user, optional
    #
    # @option [Boolean] sandbox
    #   true if using the sandbox, not production
    #
    # @option [String] checkout_type
    #   Possibilities are "mobile" and "desktop". defaults to "desktop"

    def initialize(options = {})
      super
      self.sandbox = options[:sandbox]
    end

    # Turn on/off sandbox mode.
    def sandbox=(flag)
      @sandbox = !!flag
    end

    # Test if the client is using the responsive mobile checkout.
    #
    # @return [Boolean]
    #   true if using the responsive mobile checkout
    def mobile?
      checkout_type == "mobile"
    end

    # Test if the client is using the sandbox.
    #
    # @return [Boolean]
    #   true if using the sandbox
    def sandbox?
      !!@sandbox
    end

    # Execute a Request.
    #
    # @example
    #   response = client.execute(:Refund, pay_key: "abc", amount: 42)
    #   puts response.ack_code
    #
    # @params [Symbol] operation_name
    #   The name of the operation to perform.
    #   This maps with the name of the Request class.
    #
    # @params [Hash] attributes
    #   attributes used to build the request
    #
    # @return [AbstractResponse]
    #   a response object for the given operation
    #
    # @yield [AbstractResponse]
    #   optional way to receive the return value
    def execute(*args)
      request =
        case args.size
        when 1 then args[0]
        when 2 then AbstractRequest.for_operation(args[0]).new(args[1])
        else
          raise ArgumentError, "Invalid arguments: #{args.size} for (1..2)"
        end

      resource = RestClient::Resource.new(api_url, :headers => headers)
      response = resource[request.class.operation.to_s].post(
        request.to_json,
        :content_type => :json,
        :accept       => :json
      )
      request.class.build_response(response).tap do |res|
        yield res if block_given?
      end
    rescue RestClient::Exception => e
      raise AdaptivePayments::Exception, e
    end

    # Execute an express handshake ("SetExpressCheckout") Request.
    #
    # @example
    #   response = client.express_handshake(email: "test@example.com", receiver_amount: 0.51, currency_code: "USD", return_url: "https://www.example.com/return_path", cancel_url: "https://www.example.com/cancel_path" )
    #   puts response
    #   => "TOKEN=EC%2d32P548528Y663714N&TIMESTAMP=2016%2d03%2d08T11%3a39%3a34Z&CORRELATIONID=51efed895c8a8&ACK=Success&VERSION=124&BUILD=18316154"
    #
    # @return [String]
    #   a response object for the given operation
    #
    # @yield [String]
    #   optional way to receive the return value
    def express_handshake(options)
      hash = {
        "USER" => user_id,
        "PWD" => password,
        "SIGNATURE" => signature,
        "METHOD" => "SetExpressCheckout",
        "RETURNURL" => options[:return_url], # URL of your payment confirmation page
        "CANCELURL" => options[:cancel_url], # URL redirect if customer cancels payment
        "VERSION" => 124, # this may increase in the future
        "SOLUTIONTYPE" => "Sole",
        "LANDINGPAGE" => "Billing",
        "EMAIL" => options[:email],
        "PAYMENTREQUEST_0_SELLERPAYPALACCOUNTID" => options[:receiver_email], # explictly set what paypal account will recieve the payment
        "PAYMENTREQUEST_0_PAYMENTACTION" => "SALE",
        "PAYMENTREQUEST_0_AMT" => options[:receiver_amount],
        "PAYMENTREQUEST_0_CURRENCYCODE" => options[:currency_code],
      }

      response = post_to_express_endpoint(hash)

      yield response if block_given?
    rescue RestClient::Exception => e
      raise AdaptivePayments::Exception, e
    end

    # Execute an express handshake ("SetExpressCheckout") Request.
    #
    # @example
    #   response = client.express_perform(receiver_amount: 0.51, currency_code: "USD", token: "token_returned_with_user_from_paypal", PayerID: "id_returned_with_user_from_paypal"  )
    #   puts response
    #   => "TOKEN=EC%2d77X70771J7730413M&SUCCESSPAGEREDIRECTREQUESTED=false&TIMESTAMP=2016%2d03%2d08T11%3a22%3a13Z&CORRELATIONID=46f0eef897abd&ACK=Success&VERSION=124&BUILD=18316154&INSURANCEOPTIONSELECTED=false&SHIPPINGOPTIONISDEFAULT=false&PAYMENTINFO_0_TRANSACTIONID=1BG7064136737244V&PAYMENTINFO_0_TRANSACTIONTYPE=expresscheckout&PAYMENTINFO_0_PAYMENTTYPE=instant&PAYMENTINFO_0_ORDERTIME=2016%2d03%2d08T11%3a22%3a12Z&PAYMENTINFO_0_AMT=49%2e95&PAYMENTINFO_0_TAXAMT=0%2e00&PAYMENTINFO_0_CURRENCYCODE=EUR&PAYMENTINFO_0_PAYMENTSTATUS=Pending&PAYMENTINFO_0_PENDINGREASON=multicurrency&PAYMENTINFO_0_REASONCODE=None&PAYMENTINFO_0_PROTECTIONELIGIBILITY=Ineligible&PAYMENTINFO_0_PROTECTIONELIGIBILITYTYPE=None&PAYMENTINFO_0_SECUREMERCHANTACCOUNTID=97HKEN2K8JCZY&PAYMENTINFO_0_ERRORCODE=0&PAYMENTINFO_0_ACK=Success"
    #
    # @return [String]
    #   a response object for the given operation
    #
    # @yield [String]
    #   optional way to receive the return value
    def express_perform(options)
      hash = {
        "USER" => user_id,
        "PWD" => password,
        "SIGNATURE" => signature,
        "METHOD" => "DoExpressCheckoutPayment",
        "VERSION" => 124,
        "TOKEN" => options[:token],
        "PAYERID" => options[:PayerID],
        "PAYMENTREQUEST_0_SELLERPAYPALACCOUNTID" => options[:receiver_email], # explictly set what paypal account will recieve the payment
        "PAYMENTREQUEST_0_PAYMENTACTION" => "SALE",
        "PAYMENTREQUEST_0_AMT" => options[:receiver_amount],
        "PAYMENTREQUEST_0_CURRENCYCODE" => options[:currency_code]
      }

      response = post_to_express_endpoint(hash)

      yield response if block_given?
    rescue RestClient::Exception => e
      raise AdaptivePayments::Exception, e
    end

    # / TODO # When initiating a preapproval, get the URL on paypal.com to send the user to.
    #
    # @param [PreapprovalResponse] response
    #   the response when setting up the preapproval
    #
    # @return [String]
    #   the URL on paypal.com to send the user to
    def preapproval_url(response)
      [
        "https://www.",
        ("sandbox." if sandbox?),
        "paypal.com/webscr?cmd=_ap-preapproval&preapprovalkey=",
        response.preapproval_key
      ].join
    end

    # When initiating a preapproval, get the URL on paypal.com to send the user to.
    #
    # @param [PreapprovalResponse] response
    #   the response when setting up the preapproval
    #
    # @return [String]
    #   the URL on paypal.com to send the user to
    def preapproval_url(response)
      [
        "https://www.",
        ("sandbox." if sandbox?),
        "paypal.com/webscr?cmd=_ap-preapproval&preapprovalkey=",
        response.preapproval_key
      ].join
    end

    # When initiating a payment, get the URL on paypal.com to send the user to.
    #
    # @param [PayResponse] response
    #   the response when setting up the payment
    #
    # @return [String]
    #   the URL on paypal.com to send the user to
    def payment_url(response)
      case checkout_type
      when "mobile"
        mobile_payment_url(response)
      else # for default "desktop" and as a fallback
        desktop_payment_url(response)
      end
    end

    def express_checkout_url(token)
      "https://www.#{sandbox? ? "sandbox." : ""}paypal.com/cgi-bin/webscr?cmd=_express-checkout&useraction=commit&token=#{token}"
    end

    private

    def post_to_express_endpoint(hash)
      return RestClient.post("https://api-3t.#{sandbox? ? "sandbox." : ""}paypal.com/nvp", hash)
    end

    def api_url
      [
        "https://svcs.",
        ("sandbox." if sandbox?),
        "paypal.com/AdaptivePayments"
      ].join
    end

    def desktop_payment_url(response)
      [
        "https://www.",
        ("sandbox." if sandbox?),
        "paypal.com/webscr?cmd=_ap-payment&paykey=",
        response.pay_key
      ].join
    end

    def mobile_payment_url(response)
      [
        "https://www.",
        ("sandbox." if sandbox?),
        "paypal.com/webapps/adaptivepayment/flow/pay?expType=mini&paykey=",
        response.pay_key
      ].join
    end

    def headers
      base_headers = {
        "X-PAYPAL-RESPONSE-DATA-FORMAT" => "JSON",
        "X-PAYPAL-REQUEST-DATA-FORMAT"  => "JSON"
      }
      attribute_set.inject(base_headers) do |hash, attr|
        next hash if self[attr.name].nil? || attr.options[:header].nil?
        hash.merge(attr.options[:header] => self[attr.name])
      end
    end
  end
end
