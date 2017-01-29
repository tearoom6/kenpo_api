require 'spec_helper'

describe KenpoApi::ServiceGroup do
  it 'lists resort reserve services' do
    resort_reserve_category = KenpoApi.find_service_category(:resort_reserve)
    services = resort_reserve_category.service_groups.first.services
    expect(services.count).to be <= 1
  end

end
