require 'spec_helper'

describe KenpoApi::ServiceCategory do
  it 'lists service categories' do
    service_categories = KenpoApi::ServiceCategory.list
    expect(service_categories.count).to eq(12)
  end

  it 'finds service category' do
    resort_reserve_category = KenpoApi::ServiceCategory.find(:resort_reserve)
    expect(resort_reserve_category).not_to be_nil
  end

  it 'lists resort reserve groups' do
    resort_reserve_category = KenpoApi::ServiceCategory.find(:resort_reserve)
    service_groups = resort_reserve_category.service_groups
    expect(service_groups.count).to eq(14)
  end

  it 'lists sport reserve groups' do
    sport_reserve_category = KenpoApi::ServiceCategory.find(:sport_reserve)
    service_groups = sport_reserve_category.service_groups
    expect(service_groups.count).to eq(4)
  end

  it 'finds resort reserve group' do
    resort_reserve_category = KenpoApi::ServiceCategory.find(:resort_reserve)
    service_group = resort_reserve_category.find_service_group('トスラブ館山ルアーナ')
    expect(service_group).not_to be_nil
  end

  it 'check resort reserve category available' do
    resort_reserve_category = KenpoApi::ServiceCategory.find(:resort_reserve)
    expect(resort_reserve_category.available?).to be true
  end

end
