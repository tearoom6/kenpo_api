module KenpoApi
  class Service
    attr_reader :group, :name, :path

    def initialize(group:, name:, path:)
      @group = group
      @name = name
      @path = path
    end

    def self.list(service_group)
      return [] if service_group.nil?
      Client.instance.fetch_document(path: service_group.path).xpath('//section[@class="request-box"]//a').map do |link|
        self.new(
          group: service_group,
          name: link.text,
          path: link['href'],
        )
      end
    end

    def self.find(service_group, name)
      self.list(service_group).find { |service| service.name == name }
    end

  end
end
