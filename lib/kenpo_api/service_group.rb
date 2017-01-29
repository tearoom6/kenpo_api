module KenpoApi
  class ServiceGroup
    attr_reader :category, :text, :path

    def initialize(category:, text:, path:)
      @category = category
      @text = text
      @path = path
    end

    def services
      KenpoApi.client.fetch_elements(@path, '//section[@class="request-box"]//a').map do |link|
        Service.new(
          group: self,
          text: link.text,
          path: link['href'],
        )
      end
    end

    def find_service_group(text)
      services.find { |service| service.text == text }
    end

    def available?
      self.services.any?
    end

  end
end
