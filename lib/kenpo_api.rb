require 'kenpo_api/version'
require 'kenpo_api/client'
require 'kenpo_api/service_category'
require 'kenpo_api/service_group'
require 'kenpo_api/service'
require 'kenpo_api/resort'

module KenpoApi
  class NetworkError < StandardError; end
  class NotFoundError < StandardError; end
  class NotAvailableError < StandardError; end
  class ParseError < StandardError; end

end
