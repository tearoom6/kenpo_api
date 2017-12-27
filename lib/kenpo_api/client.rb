require 'singleton'
require 'faraday'
require 'cookiejar'
require 'nokogiri'

module KenpoApi
  class Client
    include Singleton

    BASE_URL = 'https://as.its-kenpo.or.jp/'

    attr_accessor :timeout, :open_timeout

    def initialize
      @conn = Faraday.new(url: BASE_URL) do |builder|
        builder.use Faraday::Request::UrlEncoded
        builder.adapter Faraday.default_adapter
      end
      # Set default settings.
      @timeout = 5
      @open_timeout = 5
      @cookiejar = CookieJar::Jar.new
    end

    def access(path:, method: :get, params: {}, headers: {}, redirect_limit: 0)
      response = @conn.send(method, path, params) do |req|
        req.options.timeout = @timeout
        req.options.open_timeout = @open_timeout
        req.headers = headers
        req.headers['cookie'] = @cookiejar.get_cookie_header(@conn.url_prefix.to_s)
      end
      raise NetworkError.new("Failed to fetch http content. path: #{path} status_code: #{response.status}") unless (200...400).include?(response.status)

      @cookiejar.set_cookie(@conn.url_prefix.to_s, response.headers['set-cookie']) if response.headers.has_key?('set-cookie')

      if (redirect_limit > 0) && (location = response['location'])
        response = self.access(path: location, method: method, params: params, headers: headers, redirect_limit: redirect_limit - 1)
      end

      return (yield response) if block_given?
      response
    rescue KenpoApiError => e
      raise e
    rescue => e
      raise NetworkError.new("Failed to fetch http content. path: #{path} original_error: #{e.message}")
    end

    def fetch_document(path:, method: :get, params: {}, headers: {})
      response = access(path: path, method: method, params: params, headers: headers)
      document = Nokogiri::HTML(response.body)

      return (yield document) if block_given?
      document
    end

    def parse_single_form_page(path:, method: :get, params: {}, headers: {})
      document = fetch_document(path: path, method: method, params: params, headers: headers)
      form_element = document.xpath('//form').first

      next_page_info = nil
      unless form_element.nil?
        path = form_element['action']
        method = form_element['method']
        params = document.xpath('//input[@type="hidden"]').select {|input| ! input['name'].nil?}.map {|input| [input['name'], input['value']]}.to_h
        next_page_info = {path: path, method: method, params: params}
      end

      return (yield next_page_info, document) if block_given?
      return next_page_info, document
    rescue KenpoApiError => e
      raise e
    rescue => e
      raise ParseError.new("Failed to parse HTML. message: #{e.message}")
    end

  end
end
