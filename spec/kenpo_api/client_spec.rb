require 'spec_helper'

describe KenpoApi::Client do
  let(:client) do
    KenpoApi::Client.new
  end

  it 'can access kenpo webpage via HTTP GET method' do
    success_response = client.access('/service_category/index')
    expect(success_response.status).to eq(200)
  end
end
