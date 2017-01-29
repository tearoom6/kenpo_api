require 'kenpo_api/version'
require 'kenpo_api/client'
require 'kenpo_api/service_category'
require 'kenpo_api/service_group'
require 'kenpo_api/service'

module KenpoApi

  def self.service_categories
    client.fetch_elements('/service_category/index', '//div[@class="request-box"]//a').map do |link|
      ServiceCategory.new(
        text: link.text,
        path: link['href'],
      )
    end
  end

  def self.find_service_category(name)
    self.service_categories.find { |category| category.name == name }
  end

  def self.client
    @client ||= Client.new
  end

end
