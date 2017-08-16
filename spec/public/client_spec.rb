# rspec spec/public/client_spec.rb
describe AdaptivePayments::Client do
  let(:rest_client)   { double(:post => '{}').tap { |d| allow(d).to receive_messages(:[] => d) } }
  let(:request_class) { double(:operation => :Refund, :build_response => nil) }
  let(:request)       { double(:class => request_class, :to_json => '{}') }
  let(:client)        { AdaptivePayments::Client.new }

  before(:each) do
    allow(RestClient::Resource).to receive(:new).and_return(rest_client)
  end

  describe "#express_handshake(options)" do
    subject { client.express_handshake(options) }

    context "when called with no block and some custom allcaps string keys" do
      let(:options) do
        {
          email: "email@test.com",
          return_url: "https://test.com/ok",
          cancel_url: "https://test.com/error",
          receiver_email: "receiver@test.com",
          receiver_amount: "100",
          currency_code: "EUR",
          "LOCALECODE" => "ES",
          "SUBJECT" => "overriden subject",
        }
      end

      let(:exp) do
        hash_including("LOCALECODE" => "ES", "SUBJECT" => "overriden subject")
      end

      it "triggers :post_to_express_endpoint with options correctly processed, allcaps correctly overriding defaults and returns the response" do
        allow(client).to receive(:post_to_express_endpoint).and_return("test response")
        expect(client).to receive(:post_to_express_endpoint).once.with(exp)

        expect(subject).to eq("test response")
      end
    end
  end

  it "uses the production endpoint by default" do
    expect(RestClient::Resource).to receive(:new) \
      .with("https://svcs.paypal.com/AdaptivePayments", an_instance_of(Hash)) \
      .and_return(rest_client)
    client.execute(request)
  end

  it "uses the sandbox when sandbox? is true" do
    client.sandbox = true
    expect(RestClient::Resource).to receive(:new) \
      .with("https://svcs.sandbox.paypal.com/AdaptivePayments", an_instance_of(Hash)) \
      .and_return(rest_client)
    client.execute(request)
  end

  it "initializes with :checkout_type set to 'desktop'" do
    expect(client.checkout_type).to eq 'desktop'
  end

  describe "#mobile?" do
    it "should return false for default client" do
      expect(client.mobile?).to eq false
    end

    it "should return true for clients specifically initialized as mobile" do
      @client = set_up_client(false, true)
      expect(@client.mobile?).to eq true
    end
  end

  it "sends the user ID in the headers to the endpoint" do
    client.user_id = "a.user.id"
    expect(RestClient::Resource).to receive(:new) \
      .with(/^https:\/\/.*/, :headers => hash_including("X-PAYPAL-SECURITY-USERID" => "a.user.id")) \
      .and_return(rest_client)
    client.execute(request)
  end

  it "sends the password in the headers to the endpoint" do
    client.password = "123456"
    expect(RestClient::Resource).to receive(:new) \
      .with(/^https:\/\/.*/, :headers => hash_including("X-PAYPAL-SECURITY-PASSWORD" => "123456")) \
      .and_return(rest_client)
    client.execute(request)
  end

  it "sends the signature in the headers to the endpoint" do
    client.signature = "a.signature"
    expect(RestClient::Resource).to receive(:new) \
      .with(/^https:\/\/.*/, :headers => hash_including("X-PAYPAL-SECURITY-SIGNATURE" => "a.signature")) \
      .and_return(rest_client)
    client.execute(request)
  end

  it "sends the application ID in the headers to the endpoint" do
    client.app_id = "an.app.id"
    expect(RestClient::Resource).to receive(:new) \
      .with(/^https:\/\/.*/, :headers => hash_including("X-PAYPAL-APPLICATION-ID" => "an.app.id")) \
      .and_return(rest_client)
    client.execute(request)
  end

  it "sets the request format to JSON" do
    expect(RestClient::Resource).to receive(:new) \
      .with(/^https:\/\/.*/, :headers => hash_including("X-PAYPAL-REQUEST-DATA-FORMAT" => "JSON")) \
      .and_return(rest_client)
    client.execute(request)
  end

  it "sets the response format to JSON" do
    expect(RestClient::Resource).to receive(:new) \
      .with(/^https:\/\/.*/, :headers => hash_including("X-PAYPAL-RESPONSE-DATA-FORMAT" => "JSON")) \
      .and_return(rest_client)
    client.execute(request)
  end

  it "sends requests to the given API operation" do
    allow(request.class).to receive_messages(:operation => :Preapproval)
    expect(rest_client).to receive(:[]).with("Preapproval")
    client.execute(request)
  end

  it "uses the request class to build a response" do
    response = double(:response)
    expect(request_class).to receive(:build_response).and_return(response)
    expect(client.execute(request)).to eq(response)
  end

  it "allows passing a Symbol + Hash instead of a full request object" do
    expect(client.execute(:Refund, {})).to be_a_kind_of(AdaptivePayments::RefundResponse)
  end

  it "yields the response object" do
    response = double(:response)
    expect(request_class).to receive(:build_response).and_return(response)
    ret_val = nil
    client.execute(request) { |r| ret_val = r }
    expect(ret_val).to eq(response)
  end

  describe "#payment_url(response)" do
    before :all do
      @response = set_up_mock_response
    end

    context "sandbox" do
      it "should return correct sandbox desktop checkout url" do
        @client = set_up_client(true, false)
        expect(@client.payment_url(@response)).to eq "https://www.sandbox.paypal.com/webscr?cmd=_ap-payment&paykey=ABCD-1234"
      end

      it "should return correct sandbox mobile checkout url" do
        @client = set_up_client(true, true)
        expect(@client.payment_url(@response)).to eq "https://www.sandbox.paypal.com/webapps/adaptivepayment/flow/pay?expType=mini&paykey=ABCD-1234"
      end
    end

    context "production" do
      it "should return correct production desktop checkout url" do
        @client = set_up_client(false, false)
        expect(@client.payment_url(@response)).to eq "https://www.paypal.com/webscr?cmd=_ap-payment&paykey=ABCD-1234"
      end

      it "should return correct production mobile checkout url" do
        @client = set_up_client(false, true)
        expect(@client.payment_url(@response)).to eq "https://www.paypal.com/webapps/adaptivepayment/flow/pay?expType=mini&paykey=ABCD-1234"
      end
    end
  end

  #privates
  describe "#headers" do
    it "should never contain a nil key" do
      header_hash = client.send(:headers)
      expect(header_hash.keys.include?(nil)).to eq false
    end
  end

end
