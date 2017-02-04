require 'dry-validation'

module KenpoApi
  class Resort
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def request_reservation_url(email)
      # Accept agreement.
      next_page_info, = Client.instance.parse_single_form_page(path: reservation_service.path)

      # Input email.
      next_page_info, = Client.instance.parse_single_form_page(next_page_info)
      next_page_info[:params]['email'] = email

      Client.instance.access(next_page_info)
    end

    def self.apply_reservation(reservation_url, reservation_data)
      # Input application form.
      next_page_info, document = Client.instance.parse_single_form_page(path: reservation_url)
      raise NotAvailableError.new("Reservation URL is invalid: #{document.xpath('//p').first.content}") if next_page_info.nil?

      apply_data = self.validate_reservation_data(reservation_data, document)
      next_page_info[:params]['apply[sign_no]']          = apply_data[:sign_no]
      next_page_info[:params]['apply[insured_no]']       = apply_data[:insured_no]
      next_page_info[:params]['apply[office_name]']      = apply_data[:office_name]
      next_page_info[:params]['apply[kana_name]']        = apply_data[:kana_name]
      next_page_info[:params]['apply[year]']             = apply_data[:birth_year]
      next_page_info[:params]['apply[month]']            = apply_data[:birth_month]
      next_page_info[:params]['apply[day]']              = apply_data[:birth_day]
      next_page_info[:params]['apply[gender]']           = apply_data[:gender]
      next_page_info[:params]['apply[relationship]']     = apply_data[:relationship]
      next_page_info[:params]['apply[contact_phone]']    = apply_data[:contact_phone]
      next_page_info[:params]['apply[postal]']           = apply_data[:postal_code]
      next_page_info[:params]['apply[state]']            = apply_data[:state]
      next_page_info[:params]['apply[address]']          = apply_data[:address]
      next_page_info[:params]['apply[join_time]']        = apply_data[:join_time]
      next_page_info[:params]['apply[night_count]']      = apply_data[:night_count]
      next_page_info[:params]['apply[stay_persons]']     = apply_data[:stay_persons]
      next_page_info[:params]['apply[hope_rooms]']       = apply_data[:room_persons].size()
      next_page_info[:params]['apply[hope_room1]']       = apply_data[:room_persons][0]
      next_page_info[:params]['apply[hope_room2]']       = apply_data[:room_persons][1] || ''
      next_page_info[:params]['apply[hope_room3]']       = apply_data[:room_persons][2] || ''
      next_page_info[:params]['apply[hope_room4]']       = apply_data[:room_persons][3] || ''
      next_page_info[:params]['apply[hope_room5]']       = apply_data[:room_persons][4] || ''
      next_page_info[:params]['apply[hope_room6]']       = apply_data[:room_persons][5] || ''
      next_page_info[:params]['apply[hope_room7]']       = apply_data[:room_persons][6] || ''
      next_page_info[:params]['apply[hope_room8]']       = apply_data[:room_persons][7] || ''
      next_page_info[:params]['apply[hope_room9]']       = apply_data[:room_persons][8] || ''
      next_page_info[:params]['apply[hope_room10]']      = apply_data[:room_persons][9] || ''
      next_page_info[:params]['apply[use_meeting_flag]'] = apply_data[:meeting_dates].any? ? 'use' : 'no_use'
      next_page_info[:params]['apply[use_meeting1]']     = apply_data[:meeting_dates].include?(1) ? '1' : '0'
      next_page_info[:params]['apply[use_meeting2]']     = apply_data[:meeting_dates].include?(2) ? '1' : '0'
      next_page_info[:params]['apply[use_meeting3]']     = (apply_data[:meeting_dates].include?(3) && apply_data[:night_count] >= 2) ? '1' : '0'
      next_page_info[:params]['apply[must_meeting]']     = apply_data[:must_meeting] ? 'must' : 'not_must'

      # Confirm.
      next_page_info, = Client.instance.parse_single_form_page(next_page_info)

      Client.instance.access(next_page_info)
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

    def self.validate_reservation_data(reservation_data, html_document)
      reservation_data[:birth_year]    = reservation_data[:birth_year].to_s
      reservation_data[:birth_month]   = reservation_data[:birth_month].to_s
      reservation_data[:birth_day]     = reservation_data[:birth_day].to_s
      reservation_data[:state]         = reservation_data[:state].to_s
      reservation_data[:night_count]   = reservation_data[:night_count].to_s
      reservation_data[:room_persons]  = Array(reservation_data[:room_persons])
      reservation_data[:meeting_dates] = Array(reservation_data[:meeting_dates])

      birth_years   = html_document.xpath('id("apply_year")/*/@value')        .map {|attr| attr.value }.select {|val| val != '' }  # (1917..2017)
      birth_months  = html_document.xpath('id("apply_month")/*/@value')       .map {|attr| attr.value }.select {|val| val != '' }  # (1..12)
      birth_days    = html_document.xpath('id("apply_day")/*/@value')         .map {|attr| attr.value }.select {|val| val != '' }  # (1..31)
      genders       = html_document.xpath('id("apply_gender")/*/@value')      .map {|attr| attr.value }.map    {|val| val.to_sym } # [:man, :woman]
      relationships = html_document.xpath('id("apply_relationship")/*/@value').map {|attr| attr.value }.map    {|val| val.to_sym } # [:myself, :family]
      states        = html_document.xpath('id("apply_state")/*/@value')       .map {|attr| attr.value }.select {|val| val != '' }  # (1..47)
      join_times    = html_document.xpath('id("apply_join_time")/*/@value')   .map {|attr| attr.value }.select {|val| val != '' }  # ['2017-04-01', .., '2017-04-30']
      night_counts  = html_document.xpath('id("apply_night_count")/*/@value') .map {|attr| attr.value }.select {|val| val != '' }  # (1..2)
      room_numbers  = html_document.xpath('id("house_select")/*/@value')      .map {|attr| attr.value.to_i }                       # (1..10)

      schema = Dry::Validation.Schema do
        required(:sign_no)      .filled(:int?)
        required(:insured_no)   .filled(:int?)
        required(:office_name)  .filled(:str?)
        required(:kana_name)    .filled(:str?)
        required(:birth_year)   .filled(included_in?: birth_years)
        required(:birth_month)  .filled(included_in?: birth_months)
        required(:birth_day)    .filled(included_in?: birth_days)
        required(:gender)       .filled(included_in?: genders)
        required(:relationship) .filled(included_in?: relationships)
        required(:contact_phone).filled(format?: /^[0-9-]+$/)
        required(:postal_code)  .filled(format?: /^[0-9]{3}-[0-9]{4}$/)
        required(:state)        .filled(included_in?: states)
        required(:address)      .filled(:str?)
        required(:join_time)    .filled(included_in?: join_times)
        required(:night_count)  .filled(included_in?: night_counts)
        required(:stay_persons) .filled(:int?)
        required(:room_persons) .filled{ array? & each(:int?) & size?(room_numbers) }
        required(:meeting_dates).value{ array? & each{ int? & included_in?([1,2,3]) } & size?((0..3)) }
        required(:must_meeting) .maybe(:bool?)
      end

      result = schema.call(reservation_data)
      raise ValidationError.new("Reservation data is invalid. #{result.messages.to_s}") if result.failure?
      reise ValidationError.new('Stay persons count should match the sum of room persons') unless reservation_data[:stay_persons] != reservation_data[:room_persons].inject(:+)
      result.output
    end

  end
end
