require 'spec_helper'

describe KenpoApi do
  it 'has a version number' do
    expect(KenpoApi::VERSION).not_to be nil
  end

  it 'lists service categories' do
    service_categories = KenpoApi.service_categories
    expect(service_categories.count).to eq(11)
  end

  it 'finds service category' do
    resort_reserve_category = KenpoApi.find_service_category(:resort_reserve)
    expect(resort_reserve_category).not_to be_nil
  end

end
