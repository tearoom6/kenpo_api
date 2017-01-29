require 'faraday'
require 'nokogiri'

module KenpoApi
  class NetworkError < StandardError
  end

  class Client
    BASE_URL = 'https://as.its-kenpo.or.jp/'

    def initialize
      @conn = Faraday.new(url: BASE_URL) do |faraday|
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
      end
    end

    def fetch_elements(url, xpath)
      response = access(url)
      Nokogiri::HTML(response.body).xpath(xpath)
    end

    def access(path, method: :get, params: {})
      response = @conn.send(method, path, params)
      raise NetworkError.new("Failed to fetch http content. path: #{path} status_code: #{response.status}") unless response.success?
      response
    end

  end
end
