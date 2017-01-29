module KenpoApi
  class Service
    attr_reader :group, :text, :path

    def initialize(group:, text:, path:)
      @group = group
      @text = text
      @path = path
    end

  end
end
