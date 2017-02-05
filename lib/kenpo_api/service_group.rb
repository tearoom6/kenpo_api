module KenpoApi
  class ServiceGroup
    attr_reader :category, :name, :path

    def initialize(category:, name:, path:)
      @category = category
      @name = name
      @path = path
    end

    def self.list(service_category)
      return [] if service_category.nil?
      Client.instance.fetch_document(path: service_category.path).xpath('//section[@class="request-box"]//a').map do |link|
        self.new(
          category: service_category,
          name: link.text,
          path: link['href'],
        )
      end
    end

    def self.find(service_category, name)
      self.list(service_category).find { |group| group.name == name }
    end

    def services
      Service.list(self)
    end

    def find_service(name)
      Service.find(self, name)
    end

    def available?
      self.services.any?
    end

  end
end
