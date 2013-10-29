module Gmaps4rails

  class PlacesDetails
    
    include BaseNetMethods
    
    attr_reader :reference, :sensor
    delegate :key, :extensions, :lang, :raw, :protocol, :to => :@options
        
    def initialize(reference, sensor, options = {})
      @reference, @sensor = reference, sensor
      raise_missing_key unless options[:key]
      raise_invalid     unless valid_reference?
      options[:raw]     ||= false
      options[:protocol]||= "http"
      @options = OpenStruct.new options
    end
    
    def get
      checked_google_response do
        return parsed_response if raw
        memo = { 
                 :lat               => parsed_response["result"]["geometry"]["location"]["lat"], 
                 :lng               => parsed_response["result"]["geometry"]["location"]["lng"],
                 :street_number     => address_component(parsed_response["result"]["address_components"], :street_number, 'short_name'),
                 :street            => address_component(parsed_response["result"]["address_components"], :route, 'long_name'),
                 :city              => address_component(parsed_response["result"]["address_components"], :locality, 'long_name'),
                 :region            => address_component(parsed_response["result"]["address_components"], :administrative_area_level_1, 'long_name'),
                 :postal_code       => address_component(parsed_response["result"]["address_components"], :postal_code, 'long_name'),
                 :country           => address_component(parsed_response["result"]["address_components"], :country, 'long_name'),
                 :name              => parsed_response["result"]["name"],
                 :reference         => parsed_response["result"]["reference"],
                 :vicinity          => parsed_response["result"]["vicinity"],
                 :formatted_address => parsed_response["result"]["formatted_address"],
                 :full_data         => parsed_response["result"]
                }
      end
    end
    
    private
    
    def address_component(address_components, address_component_type, address_component_length)
      if component = address_components_of_type(address_components, address_component_type)
        component.first[address_component_length] unless component.first.nil?
      end
    end

    def address_components_of_type(address_components, type)
      address_components.select{ |c| c['types'].include?(type.to_s) } unless address_components.nil?
    end
    
    def base_request
      req = "#{protocol}://maps.googleapis.com/maps/api/place/details/json?&sensor=#{sensor}&key=#{key}&reference=#{reference}"
      req += "&language=#{lang}" unless lang.nil?
      req += "&extensions=#{extensions}" unless extensions.nil?
      req
    end
    
    def valid_reference?
      !(reference.nil? || reference.empty?)
    end
    
    def raise_invalid
      raise Gmaps4rails::PlacesInvalidQuery, "You must provide at least a reference for a Google places autocomplete query"
    end
    
    def raise_missing_key
      raise "Google Places API requires an API key"
    end
    
    def raise_net_status
      raise Gmaps4rails::PlacesNetStatus, "The request sent to google was invalid (not http success): #{base_request}.\nResponse was: #{response}"
    end
    
    def raise_query_error
      raise Gmaps4rails::PlacesStatus, "The address you passed seems invalid, status was: #{parsed_response["status"]}.\nRequest was: #{base_request}"
    end
    
    def get_response
      uri     = URI.parse(base_url)
      http    = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl     = true # Places API wants https
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE # to avoid any cert issues
      http.request(Net::HTTP::Get.new(uri.request_uri))
    end
    
  end
end