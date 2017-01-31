module KenpoApi
  class ServiceGroup
    attr_reader :category, :text, :path

    def initialize(category:, text:, path:)
      @category = category
      @text = text
      @path = path
    end

    def self.list(service_category)
      return [] if service_category.nil?
      Client.instance.fetch_elements(service_category.path, '//section[@class="request-box"]//a').map do |link|
        self.new(
          category: service_category,
          text: link.text,
          path: link['href'],
        )
      end
    end

    def self.find(service_category, text)
      self.list(service_category).find { |group| group.text == text }
    end

    def services
      Service.list(self)
    end

    def find_service(text)
      Service.find(self, text)
    end

    def available?
      self.services.any?
    end

  end
end
