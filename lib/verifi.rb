require 'rubygems'
require 'httpclient'
require 'xmlsimple'
require 'active_support'

module Verifi
  class Client
    def initialize api_key, api_secret, api_host="http://localhost:3000"
      @api_key = api_key
      @api_secret = api_secret
      @api_host = api_host
    end

    #The attributes should simply be a hash of attribute name to value
    #i.e. should not be wrapped with payment[<attribute_name>]
    def create_payment_request attributes
      uri = '/payment_requests'

      params = {:payment => attributes}
      params.merge!(base_api_params.merge(:command => 'create_payment_request'))
      params.merge!(:sig => gen_sig(params, @api_secret))

      begin
        httpclient = HTTPClient.new @api_host
        @resp = httpclient.post "#{@api_host}#{uri}", params.to_query
      rescue
        puts "creating a payment request just ate a fail sandwich: #{$!.inspect}"
        return nil
      end

      XmlSimple.xml_in(@resp.content, {'ForceArray' => false, 'keeproot' => false})
    end

    def read_payment_request pay_key
      uri = "/payment_requests/#{pay_key}"

      params = {}
      params.merge!(base_api_params.merge(:command => 'read_payment_request'))
      params.merge!(:sig => gen_sig(params, @api_secret))

      begin
        httpclient = HTTPClient.new @api_host
        @resp = httpclient.get "#{@api_host}#{uri}", params.to_query
      rescue
        puts "reading payment request jus  t ate a fail sandwich: #{$!.inspect}"
        return nil
      end

      XmlSimple.xml_in(@resp.content, {'ForceArray' => false, 'keeproot' => false})
    end

    def base_api_params
      {:api_key => @api_key, :format => 'xml', :version => '1.0'}
    end

    def gen_sig params, secret
      req_params = CGI.unescape(params.to_query).split('&').sort.to_s
      Digest::SHA2.hexdigest("#{req_params}#{secret}")
    end
  end

end
