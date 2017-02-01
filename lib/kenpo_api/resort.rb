module KenpoApi
  class Resort
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def request_reservation_url(email)
      # Accept agreement.
      document = Client.instance.fetch_document(reservation_service.path)
      form_element = document.xpath('//form').first
      path = form_element['action']
      method = form_element['method']
      params = document.xpath('//input[@type="hidden"]').map {|input| [input['name'], input['value']]}.to_h

      # Input email.
      document = Client.instance.fetch_document(path, method: method, params: params)
      form_element = document.xpath('//form').first
      path = form_element['action']
      method = form_element['method']
      params = document.xpath('//input[@type="hidden"]').map {|input| [input['name'], input['value']]}.to_h
      params['email'] = email

      Client.instance.access(path, method: method, params: params)
    rescue NetworkError => e
      raise e
    rescue => e
      raise ParseError.new("Failed to parse HTML. message: #{e.message}")
    end

    def apply_reservation(reservation_url)
      # TODO
    end

    private

    def reservation_service
      @reservation_service ||= begin
        category = ServiceCategory.find(:resort_reserve)
        raise NotFoundError.new('Service category not found.') if category.nil?
        group = category.find_service_group(@name)
        raise NotFoundError.new("Service group not found. name: #{@name}") if group.nil?
        raise NotAvailableError.new("No available services. name: #{@name}") unless group.available?
        # No more two reservation services provided.
        group.services.first
      end
    end

  end
end
