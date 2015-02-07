require "share_a_sale/version"
require 'digest'
require 'uri'
require 'rest-client'

module ShareASale
  SHARE_A_SALE_HOST = "shareasale.com"
  SHARE_A_SALE_PATH = "/w.cfm"
  SHARE_A_SALE_VERSION = "1.8"

  class Client < Struct.new(:token, :api_secret, :affiliateId)

    def activity(options = {}, date = Time.now)
      request('activity', options, date).execute!
    end

    def request(action, options, date = Time.now)
      Request.new(token, api_secret, action, affiliateId,  options, date)
    end
  end

  class Request < Struct.new(:token, :api_secret, :action, :affiliateId, :options, :date)
    def date_string
      date.strftime("%a, %d %b %Y %H:%M:%S GMT")
    end

    def string_to_hash
      "#{token}:#{date_string}:#{action}:#{api_secret}"
    end

    def authentication_hash
      Digest::SHA256.hexdigest(string_to_hash).upcase
    end

    def url
      params = [['token', token], ['version', SHARE_A_SALE_VERSION], ['affiliateId', affiliateId], ['action', action], ['dateStart', date.strftime("%D")]] + options.to_a
      URI::HTTPS.build(host: SHARE_A_SALE_HOST, path: SHARE_A_SALE_PATH, query: URI.encode_www_form(params)).to_s
    end

    def custom_headers
      {
        "x-ShareASale-Date" => date_string,
        "x-ShareASale-Authentication" => authentication_hash
      }
    end

    def execute!
      RestClient.get(url, custom_headers)
    end
  end
end
