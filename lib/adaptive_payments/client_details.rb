module AdaptivePayments
  module ClientDetails
    def self.included(base)
      base.instance_eval do
        attribute :client_ip_address,     String, :param => "clientDetails.ipAddress"
        attribute :client_device_id,      String, :param => "clientDetails.deviceId"
        attribute :client_application_id, String, :param => "clientDetails.applicationId"
        attribute :client_model,          String, :param => "clientDetails.model"
        attribute :client_geo_location,   String, :param => "clientDetails.geoLocation"
        attribute :client_customer_type,  String, :param => "clientDetails.customerType"
        attribute :client_partner_name,   String, :param => "clientDetails.partnerName"
        attribute :client_customer_id,    String, :param => "clientDetails.customerId"
      end

      alias_method :extended, :included
    end
  end
end
