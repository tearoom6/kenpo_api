require 'singleton'
require 'faraday'
require 'nokogiri'

module KenpoApi
  class Client
    include Singleton

    BASE_URL = 'https://as.its-kenpo.or.jp/'

    attr_accessor :timeout, :open_timeout

    def initialize
      @conn = Faraday.new(url: BASE_URL) do |faraday|
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
      end
      # Set default settings.
      @timeout = 5
      @open_timeout = 5
    end

    def fetch_elements(url, xpath)
      response = access(url)
      Nokogiri::HTML(response.body).xpath(xpath)
    end

    def access(path, method: :get, params: {})
      response = @conn.send(method, path, params) do |req|
        req.options.timeout = @timeout
        req.options.open_timeout = @open_timeout
      end
      raise NetworkError.new("Failed to fetch http content. path: #{path} status_code: #{response.status}") unless response.success?
      response
    rescue => e
      raise NetworkError.new("Failed to fetch http content. path: #{path} original_error: #{e.message}")
    end

  end
end
