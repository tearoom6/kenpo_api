module KenpoApi
  class Service
    attr_reader :group, :text, :path

    def initialize(group:, text:, path:)
      @group = group
      @text = text
      @path = path
    end

    def self.list(service_group)
      return [] if service_group.nil?
      Client.instance.fetch_document(path: service_group.path).xpath('//section[@class="request-box"]//a').map do |link|
        self.new(
          group: service_group,
          text: link.text,
          path: link['href'],
        )
      end
    end

    def self.find(service_group, text)
      self.list(service_group).find { |service| service.text == text }
    end

  end
end
