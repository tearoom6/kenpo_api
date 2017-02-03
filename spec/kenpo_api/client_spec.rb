require 'spec_helper'

describe KenpoApi::Client do
  let(:client) do
    KenpoApi::Client.instance
  end

  it 'can access kenpo webpage via HTTP GET method' do
    success_response = client.access(path: '/service_category/index')
    expect(success_response.status).to eq(200)
  end
end
