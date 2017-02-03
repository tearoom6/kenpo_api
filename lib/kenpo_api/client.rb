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

    def access(path:, method: :get, params: {})
      response = @conn.send(method, path, params) do |req|
        req.options.timeout = @timeout
        req.options.open_timeout = @open_timeout
        req.headers['cookie'] = @cookiejar.get_cookie_header(@conn.url_prefix.to_s)
      end
      raise NetworkError.new("Failed to fetch http content. path: #{path} status_code: #{response.status}") unless response.success?

      @cookiejar.set_cookie(@conn.url_prefix.to_s, response.headers['set-cookie']) if response.headers.has_key?('set-cookie')

      return (yield response) if block_given?
      response
    rescue KenpoApiError => e
      raise e
    rescue => e
      raise NetworkError.new("Failed to fetch http content. path: #{path} original_error: #{e.message}")
    end

    def fetch_document(path:, method: :get, params: {})
      response = access(path: path, method: method, params: params)
      document = Nokogiri::HTML(response.body)

      return (yield document) if block_given?
      document
    end

    def parse_single_form_page(path:, method: :get, params: {})
      document = fetch_document(path: path, method: method, params: params)
      form_element = document.xpath('//form').first
      path = form_element['action']
      method = form_element['method']
      params = document.xpath('//input[@type="hidden"]').map {|input| [input['name'], input['value']]}.to_h
      next_page_info = {path: path, method: method, params: params}

      return (yield next_page_info) if block_given?
      next_page_info
    rescue KenpoApiError => e
      raise e
    rescue => e
      raise ParseError.new("Failed to parse HTML. message: #{e.message}")
    end

  end
end
