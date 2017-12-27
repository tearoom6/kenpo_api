require 'dry-validation'

module KenpoApi
  class Resort
    extend Routines

    def self.resort_names
      category = ServiceCategory.find(:resort_reserve)
      raise NotFoundError.new("Service category not found. code: #{category_code}") if category.nil?
      category.service_groups.map {|group| group.name}
    end

    def self.request_reservation_url(resort_name:, email:)
      service = find_service(category_code: :resort_reserve, group_name: resort_name)
      request_application_url(service_path: service.path, email: email)
    end

    def self.check_reservation_criteria(application_url, type: :lottery)
      html_document = Client.instance.fetch_document(path: application_url)
      raise NotAvailableError.new("Application URL is invalid: #{html_document.xpath('//p').first.content}") if html_document.xpath('//form').first.nil?
      reservation_criteria(html_document, type: type)
    end

    def self.apply_reservation(application_url, application_data, type: :lottery)
      apply(application_url: application_url) do |html_document|
        reservation_data = self.validate_reservation_data(application_data, html_document, type: type)
        convert_to_reservation_post_params(reservation_data, type: type)
      end
    end

    def self.check_vacant_search_criteria(resort_name:)
      service = find_service(category_code: :resort_search_vacant, group_name: resort_name)
      html_document = Client.instance.fetch_document(path: service.path)
      raise NotAvailableError.new("Application URL is invalid: #{html_document.xpath('//p').first.content}") if html_document.xpath('//form').first.nil?
      vacant_search_criteria(html_document)
    end

    def self.search_vacant_rooms(resort_name:, search_condition:)
      vacant_rooms_info = prepare_for_vacant_rooms_reservation(resort_name, search_condition)
      vacant_rooms_info[:vacant_rooms]
    end

    def self.request_reservation_url_for_vacant_rooms(resort_name:, search_condition:, vacant_room_id:, email:)
      vacant_rooms_info = prepare_for_vacant_rooms_reservation(resort_name, search_condition)
      params = vacant_rooms_info[:params].merge({"apply[coma[#{vacant_room_id}]]" => vacant_room_id})
      response = Client.instance.access(path: vacant_rooms_info[:path], method: vacant_rooms_info[:method], params: params)
      if response.status == 200
        document = Nokogiri::HTML(response.body)
        raise NotAvailableError.new("Application URL is invalid: #{document.xpath('id("errorExplanation")').first.content}")
      end
      request_application_url(service_path: response.headers['location'], email: email)
    end

    private

    def self.prepare_for_vacant_rooms_reservation(resort_name, search_condition)
      service = find_service(category_code: :resort_search_vacant, group_name: resort_name)
      next_page_info, html_document = Client.instance.parse_single_form_page(path: service.path)
      raise NotAvailableError.new("Application URL is invalid: #{html_document.xpath('//p').first.content}") if next_page_info.nil?

      # Call Ajax API to search vacant rooms.
      search_condition = self.validate_vacant_search_condition(search_condition, html_document)
      params = convert_to_vacant_search_post_params(search_condition)
      params = params.merge(next_page_info[:params])
      query_params = URI::parse(next_page_info[:path]).query
      headers = {'X-Requested-With' => 'XMLHttpRequest'}
      ajax_response = Client.instance.access(path: "/apply/empty_new?#{query_params}", method: :post, params: params, headers: headers)

      # Parse Ajax response.
      matched = /\<\\\/script\>(.+)\"\)\;/.match(ajax_response.body)
      ajax_document = Nokogiri::HTML(matched[1].gsub(/\\n/, '').gsub(/\s{2,}/, '').gsub(/\\/, ''))
      ids = ajax_document.xpath('id("coma_search_result")/tr/td/input/@value').map {|attr| attr.value }

      vacant_rooms = ajax_document.xpath('id("coma_search_result")/tr').map.with_index do |elem, index|
        values = elem.xpath('td/text()').map {|text| text.content }
        {
          id:           ids[index],
          room_number:  values[0],
          join_time:    values[1],
          room_type:    values[2],
          room_persons: values[3],
          room_status:  values[4],
        }
      end

      additional_params = ajax_document.xpath('//input[@type="hidden"]').select {|input| ! input['name'].nil?}.map {|input| [input['name'], input['value']]}.to_h
      params = params.merge(additional_params)
      {
        path: next_page_info[:path],
        method: next_page_info[:method],
        params: params,
        vacant_rooms: vacant_rooms,
      }
    end

    def self.reservation_criteria(html_document, type: :lottery)
      criteria = {}
      criteria[:note]          = html_document.xpath('//div[@class="note mb10"]').first.text
      criteria[:service_name]  = html_document.xpath('//form/div[@class="form_box"]//dd[@class="elements"]').first.text
      criteria[:birth_year]   = html_document.xpath('id("apply_year")/*/@value')        .map {|attr| attr.value }.select {|val| val != '' }  # (1917..2017)
      criteria[:birth_month]  = html_document.xpath('id("apply_month")/*/@value')       .map {|attr| attr.value }.select {|val| val != '' }  # (1..12)
      criteria[:birth_day]    = html_document.xpath('id("apply_day")/*/@value')         .map {|attr| attr.value }.select {|val| val != '' }  # (1..31)
      criteria[:gender]       = html_document.xpath('id("apply_gender")/*/@value')      .map {|attr| attr.value }.map    {|val| val.to_sym } # [:man, :woman]
      criteria[:relationship] = html_document.xpath('id("apply_relationship")/*/@value').map {|attr| attr.value }.map    {|val| val.to_sym } # [:myself, :family]
      criteria[:state]        = html_document.xpath('id("apply_state")/*/@value')       .map {|attr| attr.value }.select {|val| val != '' }  # (1..47)
      if type == :lottery
        criteria[:join_time]    = html_document.xpath('id("apply_join_time")/*/@value')   .map {|attr| attr.value }.select {|val| val != '' }  # ['2017-04-01', .., '2017-04-30']
        criteria[:night_count]  = html_document.xpath('id("apply_night_count")/*/@value') .map {|attr| attr.value }.select {|val| val != '' }  # (1..2)
        criteria[:room_count]   = html_document.xpath('id("house_select")/*/@value')      .map {|attr| attr.value.to_i }                       # (1..10)
      end
      criteria
    end

    def self.vacant_search_criteria(html_document)
      criteria = {}
      criteria[:join_time]    = html_document.xpath('id("apply_join_time")/*/@value')   .map {|attr| attr.value }.select {|val| val != '' }  # ['2017-04-01', .., '2017-04-30']
      criteria[:night_count]  = html_document.xpath('id("apply_night_count")/*/@value') .map {|attr| attr.value }.select {|val| val != '' }  # (1..2)
      criteria[:room_count]   = html_document.xpath('id("house_select")/*/@value')      .map {|attr| attr.value.to_i }                       # (1..10)
      criteria
    end

    def self.preprocess_reservation_data(reservation_data, type: :lottery)
      reservation_data[:birth_year]    = reservation_data[:birth_year].to_s
      reservation_data[:birth_month]   = reservation_data[:birth_month].to_s
      reservation_data[:birth_day]     = reservation_data[:birth_day].to_s
      reservation_data[:state]         = reservation_data[:state].to_s
      if type == :lottery
        reservation_data[:night_count]   = reservation_data[:night_count].to_s
        reservation_data[:room_persons]  = Array(reservation_data[:room_persons])
        reservation_data[:meeting_dates] = Array(reservation_data[:meeting_dates])
      end
      reservation_data
    end

    def self.preprocess_vacant_search_condition(search_condition)
      search_condition[:night_count]   = search_condition[:night_count].to_s
      search_condition[:room_persons]  = Array(search_condition[:room_persons])
      search_condition
    end

    def self.validate_reservation_data(reservation_data, html_document, type: :lottery)
      reservation_data = preprocess_reservation_data(reservation_data, type: type)
      criteria = reservation_criteria(html_document, type: type)

      schema = Dry::Validation.Schema do
        required(:sign_no)      .filled(:int?)
        required(:insured_no)   .filled(:int?)
        required(:office_name)  .filled(:str?)
        required(:kana_name)    .filled(:str?)
        required(:birth_year)   .filled(included_in?: criteria[:birth_year])
        required(:birth_month)  .filled(included_in?: criteria[:birth_month])
        required(:birth_day)    .filled(included_in?: criteria[:birth_day])
        required(:gender)       .filled(included_in?: criteria[:gender])
        required(:relationship) .filled(included_in?: criteria[:relationship])
        required(:contact_phone).filled(format?: /^[0-9-]+$/)
        required(:postal_code)  .filled(format?: /^[0-9]{3}-[0-9]{4}$/)
        required(:state)        .filled(included_in?: criteria[:state])
        required(:address)      .filled(:str?)
        if type == :lottery
          required(:join_time)    .filled(included_in?: criteria[:join_time])
          required(:night_count)  .filled(included_in?: criteria[:night_count])
          required(:stay_persons) .filled(:int?)
          required(:room_persons) .filled{ array? & each(:int?) & size?(criteria[:room_count]) }
          required(:meeting_dates).value{ array? & each{ int? & included_in?([1,2,3]) } & size?((0..3)) }
          required(:must_meeting) .maybe(:bool?)
        end
      end

      result = schema.call(reservation_data)
      raise ValidationError.new("Reservation data is invalid. #{result.messages.to_s}") if result.failure?
      raise ValidationError.new('Stay persons count should match the sum of room persons') unless reservation_data[:stay_persons] == reservation_data[:room_persons].inject(:+)
      result.output
    end

    def self.validate_vacant_search_condition(search_condition, html_document)
      search_condition = preprocess_vacant_search_condition(search_condition)
      criteria = vacant_search_criteria(html_document)

      schema = Dry::Validation.Schema do
        required(:join_time)    .filled(included_in?: criteria[:join_time])
        required(:night_count)  .filled(included_in?: criteria[:night_count])
        required(:stay_persons) .filled(:int?)
        required(:room_persons) .filled{ array? & each(:int?) & size?(criteria[:room_count]) }
      end

      result = schema.call(search_condition)
      raise ValidationError.new("Search condition is invalid. #{result.messages.to_s}") if result.failure?
      raise ValidationError.new('Stay persons count should match the sum of room persons') unless search_condition[:stay_persons] == search_condition[:room_persons].inject(:+)
      result.output
    end

    def self.convert_to_reservation_post_params(original_data, type: :lottery)
      post_params = {}
      post_params['apply[sign_no]']          = original_data[:sign_no]
      post_params['apply[insured_no]']       = original_data[:insured_no]
      post_params['apply[office_name]']      = original_data[:office_name]
      post_params['apply[kana_name]']        = original_data[:kana_name]
      post_params['apply[year]']             = original_data[:birth_year]
      post_params['apply[month]']            = original_data[:birth_month]
      post_params['apply[day]']              = original_data[:birth_day]
      post_params['apply[gender]']           = original_data[:gender]
      post_params['apply[relationship]']     = original_data[:relationship]
      post_params['apply[contact_phone]']    = original_data[:contact_phone]
      post_params['apply[postal]']           = original_data[:postal_code]
      post_params['apply[state]']            = original_data[:state]
      post_params['apply[address]']          = original_data[:address]
      if type == :lottery
        post_params['apply[join_time]']        = original_data[:join_time]
        post_params['apply[night_count]']      = original_data[:night_count]
        post_params['apply[stay_persons]']     = original_data[:stay_persons]
        post_params['apply[hope_rooms]']       = original_data[:room_persons].size()
        post_params['apply[hope_room1]']       = original_data[:room_persons][0]
        post_params['apply[hope_room2]']       = original_data[:room_persons][1] || ''
        post_params['apply[hope_room3]']       = original_data[:room_persons][2] || ''
        post_params['apply[hope_room4]']       = original_data[:room_persons][3] || ''
        post_params['apply[hope_room5]']       = original_data[:room_persons][4] || ''
        post_params['apply[hope_room6]']       = original_data[:room_persons][5] || ''
        post_params['apply[hope_room7]']       = original_data[:room_persons][6] || ''
        post_params['apply[hope_room8]']       = original_data[:room_persons][7] || ''
        post_params['apply[hope_room9]']       = original_data[:room_persons][8] || ''
        post_params['apply[hope_room10]']      = original_data[:room_persons][9] || ''
        post_params['apply[use_meeting_flag]'] = original_data[:meeting_dates].any? ? 'use' : 'no_use'
        post_params['apply[use_meeting1]']     = original_data[:meeting_dates].include?(1) ? '1' : '0'
        post_params['apply[use_meeting2]']     = original_data[:meeting_dates].include?(2) ? '1' : '0'
        post_params['apply[use_meeting3]']     = (original_data[:meeting_dates].include?(3) && original_data[:night_count] >= 2) ? '1' : '0'
        post_params['apply[must_meeting]']     = original_data[:must_meeting] ? 'must' : 'not_must'
      end
      post_params
    end

    def self.convert_to_vacant_search_post_params(original_data)
      post_params = {}
      post_params['apply[join_time]']        = original_data[:join_time]
      post_params['apply[night_count]']      = original_data[:night_count]
      post_params['apply[stay_persons]']     = original_data[:stay_persons]
      post_params['apply[hope_rooms]']       = original_data[:room_persons].size()
      post_params['apply[hope_room1]']       = original_data[:room_persons][0]
      post_params['apply[hope_room2]']       = original_data[:room_persons][1] || ''
      post_params['apply[hope_room3]']       = original_data[:room_persons][2] || ''
      post_params['apply[hope_room4]']       = original_data[:room_persons][3] || ''
      post_params['apply[hope_room5]']       = original_data[:room_persons][4] || ''
      post_params['apply[hope_room6]']       = original_data[:room_persons][5] || ''
      post_params['apply[hope_room7]']       = original_data[:room_persons][6] || ''
      post_params['apply[hope_room8]']       = original_data[:room_persons][7] || ''
      post_params['apply[hope_room9]']       = original_data[:room_persons][8] || ''
      post_params['apply[hope_room10]']      = original_data[:room_persons][9] || ''
      post_params
    end

  end
end
