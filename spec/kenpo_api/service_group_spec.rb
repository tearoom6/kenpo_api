require 'spec_helper'

describe KenpoApi::ServiceGroup do
  it 'lists service groups' do
    resort_reserve_category = KenpoApi::ServiceCategory.find(:resort_reserve)
    service_groups = KenpoApi::ServiceGroup.list(resort_reserve_category)
    expect(service_groups.count).to eq(14)
  end

  it 'finds service group' do
    resort_reserve_category = KenpoApi::ServiceCategory.find(:resort_reserve)
    service_group = KenpoApi::ServiceGroup.find(resort_reserve_category, 'トスラブ館山ルアーナ')
    expect(service_group).not_to be_nil
  end

  it 'lists resort reserve services' do
    resort_reserve_category = KenpoApi::ServiceCategory.find(:resort_reserve)
    services = resort_reserve_category.service_groups.first.services
    expect(services.count).to be <= 1
  end

end
