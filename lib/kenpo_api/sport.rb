require 'dry-validation'

module KenpoApi
  class Sport
    extend Routines

    def self.sport_names
      category = ServiceCategory.find(:sport_reserve)
      raise NotFoundError.new("Service category not found. code: #{category_code}") if category.nil?
      category.service_groups.map {|group| group.name}
    end

    def self.request_reservation_url(sport_name:, email:)
      service = find_service(category_code: :sport_reserve, group_name: sport_name)
      request_application_url(service_path: service.path, email: email)
    end

    def self.check_reservation_criteria(application_url)
      html_document = Client.instance.fetch_document(path: application_url)
      raise NotAvailableError.new("Application URL is invalid: #{html_document.xpath('//p').first.content}") if html_document.xpath('//form').first.nil?
      reservation_criteria(html_document)
    end

    def self.apply_reservation(application_url, application_data)
      apply(application_url: application_url) do |html_document|
        reservation_data = self.validate_reservation_data(application_data, html_document)
        convert_to_reservation_post_params(reservation_data)
      end
    end

    private

    def self.reservation_criteria(html_document)
      criteria = {}
      criteria[:note]          = html_document.xpath('//div[@class="note mb10"]').first.text
      criteria[:service_name]  = html_document.xpath('//form/div[@class="form_box"]//dd[@class="elements"]').first.text
      criteria[:birth_year]    = html_document.xpath('id("apply_year")/*/@value')         .map {|attr| attr.value }.select {|val| val != '' }  # (1917..2017)
      criteria[:birth_month]   = html_document.xpath('id("apply_month")/*/@value')        .map {|attr| attr.value }.select {|val| val != '' }  # (1..12)
      criteria[:birth_day]     = html_document.xpath('id("apply_day")/*/@value')          .map {|attr| attr.value }.select {|val| val != '' }  # (1..31)
      criteria[:state]         = html_document.xpath('id("apply_state")/*/@value')        .map {|attr| attr.value }.select {|val| val != '' }  # (1..47)
      criteria[:join_time]     = html_document.xpath('id("apply_join_time")/*/@value')    .map {|attr| attr.value }.select {|val| val != '' }  # ['2017-04-01', .., '2017-04-30'] (only Saterdays or Sundays?)
      criteria[:use_time_from] = html_document.xpath('id("apply_use_time_from")/*/@value').map {|attr| attr.value }.select {|val| val != '' }  # ['00:00', .., '24:00']
      criteria[:use_time_to]   = html_document.xpath('id("apply_use_time_to")/*/@value')  .map {|attr| attr.value }.select {|val| val != '' }  # ['00:00', .., '24:00']
      criteria
    end

    def self.preprocess_reservation_data(reservation_data)
      reservation_data[:birth_year]    = reservation_data[:birth_year].to_s
      reservation_data[:birth_month]   = reservation_data[:birth_month].to_s
      reservation_data[:birth_day]     = reservation_data[:birth_day].to_s
      reservation_data[:state]         = reservation_data[:state].to_s
      reservation_data
    end

    def self.validate_reservation_data(reservation_data, html_document)
      reservation_data = preprocess_reservation_data(reservation_data)
      criteria = reservation_criteria(html_document)

      schema = Dry::Validation.Schema do
        required(:sign_no)      .filled(:int?)
        required(:insured_no)   .filled(:int?)
        required(:office_name)  .filled(:str?)
        required(:kana_name)    .filled(:str?)
        required(:birth_year)   .filled(included_in?: criteria[:birth_year])
        required(:birth_month)  .filled(included_in?: criteria[:birth_month])
        required(:birth_day)    .filled(included_in?: criteria[:birth_day])
        required(:contact_phone).filled(format?: /^[0-9-]+$/)
        required(:postal_code)  .filled(format?: /^[0-9]{3}-[0-9]{4}$/)
        required(:state)        .filled(included_in?: criteria[:state])
        required(:address)      .filled(:str?)
        required(:join_time)    .filled(included_in?: criteria[:join_time])
        required(:use_time_from).filled(included_in?: criteria[:use_time_from])
        required(:use_time_to)  .filled(included_in?: criteria[:use_time_to])
      end

      result = schema.call(reservation_data)
      raise ValidationError.new("Reservation data is invalid. #{result.messages.to_s}") if result.failure?
      result.output
    end

    def self.convert_to_reservation_post_params(original_data)
      post_params = {}
      post_params['apply[sign_no]']          = original_data[:sign_no]
      post_params['apply[insured_no]']       = original_data[:insured_no]
      post_params['apply[office_name]']      = original_data[:office_name]
      post_params['apply[kana_name]']        = original_data[:kana_name]
      post_params['apply[year]']             = original_data[:birth_year]
      post_params['apply[month]']            = original_data[:birth_month]
      post_params['apply[day]']              = original_data[:birth_day]
      post_params['apply[contact_phone]']    = original_data[:contact_phone]
      post_params['apply[postal]']           = original_data[:postal_code]
      post_params['apply[state]']            = original_data[:state]
      post_params['apply[address]']          = original_data[:address]
      post_params['apply[join_time]']        = original_data[:join_time]
      post_params['apply[use_time_from]']    = original_data[:use_time_from]
      post_params['apply[use_time_to]']      = original_data[:use_time_to]
      post_params
    end

  end
end
