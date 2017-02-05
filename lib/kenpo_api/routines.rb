module KenpoApi
  module Routines

    # Returns first service if you specify nil to service_name.
    def find_service(category_code:, group_name:, service_name: nil)
      category = ServiceCategory.find(category_code.to_sym)
      raise NotFoundError.new("Service category not found. code: #{category_code}") if category.nil?

      group = category.find_service_group(group_name)
      raise NotFoundError.new("Service group not found. name: #{group_name}") if group.nil?
      raise NotAvailableError.new("No available services. name: #{group_name}") unless group.available?

      return group.services.first if service_name.nil?
      service = group.find_service(service_name)
      raise NotFoundError.new("Service not found. name: #{service_name}") if service.nil?
      service
    end

    def request_application_url(service_path:, email:)
      # Accept agreement.
      next_page_info, = Client.instance.parse_single_form_page(path: service_path)

      # Input email.
      next_page_info, = Client.instance.parse_single_form_page(next_page_info)
      next_page_info[:params]['email'] = email

      Client.instance.access(next_page_info)
    end

    # Block param receives one argument (html_document), and should return additional POST params.
    def apply(application_url:)
      # Input application form.
      next_page_info, html_document = Client.instance.parse_single_form_page(path: application_url)
      raise NotAvailableError.new("Application URL is invalid: #{html_document.xpath('//p').first.content}") if next_page_info.nil?

      next_page_info[:params].merge!(yield html_document) if block_given?

      # Confirm.
      next_page_info, = Client.instance.parse_single_form_page(next_page_info)

      Client.instance.access(next_page_info)
    end

  end
end
