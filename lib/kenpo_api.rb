require 'kenpo_api/version'
require 'kenpo_api/client'
require 'kenpo_api/service_category'
require 'kenpo_api/service_group'
require 'kenpo_api/service'
require 'kenpo_api/routines'
require 'kenpo_api/resort'
require 'kenpo_api/sport'

module KenpoApi
  class KenpoApiError     < StandardError; end
  class NetworkError      < KenpoApiError; end
  class NotFoundError     < KenpoApiError; end
  class NotAvailableError < KenpoApiError; end
  class ParseError        < KenpoApiError; end
  class ValidationError   < KenpoApiError; end

end
