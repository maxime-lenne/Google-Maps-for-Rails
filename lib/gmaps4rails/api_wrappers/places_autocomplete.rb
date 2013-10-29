module Gmaps4rails

  class PlacesAutocomplete
    
    include BaseNetMethods
    
    attr_reader :input, :sensor
    delegate :key, :lat, :lng, :radius, :lang, :raw, :protocol, :offset, :types, :components, :to => :@options
        
    def initialize(input, sensor, options = {})
      @input, @sensor = input, sensor
      raise_missing_key unless options[:key]
      raise_invalid     unless valid_input?
      #options[:lat]  ||= 7500
      #options[:lng]  ||= 7500
      #options[:radius]  ||= 7500
      #options[:lang]    ||= "en"
      options[:raw]     ||= false
      options[:protocol]||= "http"
      @options = OpenStruct.new options
    end
    
    def get
      checked_google_response do
        return parsed_response if raw
        parsed_response["predictions"].inject([]) do |memo, result|
          memo << { 
                   :description       => result["name"],
                   :reference         => result["reference"],
                   :types             => result["types"],
                   :full_data => result
                  }
        end
      end
    end
    
    private
    
    def base_request
      req = "#{protocol}://maps.googleapis.com/maps/api/place/autocomplete/json?&sensor=#{sensor}&key=#{key}&input=#{input}"
      req += "&language=#{lang}" unless lang.nil?
      req += "&location=#{lat},#{lng}&radius=#{radius}" unless lat.nil? and lng.nil? and radius.nil?
      req += "&offset=#{offset}" unless offset.nil?
      req += "&types=#{types}" unless types.nil?
      req += "&components=#{components}" unless components.nil?
      req
    end
    
    def valid_input?
      !(input.nil? || input.empty?)
    end
    
    def raise_invalid
      raise Gmaps4rails::PlacesInvalidQuery, "You must provide at least an input for a Google places autocomplete query"
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