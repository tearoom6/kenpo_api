module KenpoApi
  class Resort
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def request_reservation_url(email)
      # Accept agreement.
      next_page_info = Client.instance.parse_single_form_page(path: reservation_service.path)

      # Input email.
      next_page_info = Client.instance.parse_single_form_page(next_page_info)
      next_page_info[:params]['email'] = email

      Client.instance.access(next_page_info)
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
