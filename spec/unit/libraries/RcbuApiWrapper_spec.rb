#
# Cookbook Name:: rackspace_cloudbackup
#
# Copyright 2014, Rackspace, US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'
require 'webmock/rspec'

require_relative '../../../libraries/RcbuApiWrapper.rb'

#include Opscode::Rackspace::CloudBackup
include WebMock::API

module RcbuApiWrapperTestHelpers
  def test_data
    return {
      api_username: 'Test API Username',
      api_key:      'Test API Key',
      region:       'TESTREGION',    # Needs to be UPCASE
      agent_id:     'Test Agent ID', # I believe in the real API this needs to be an int, but our code doesn't care
      api_url:      'http://mockidentity.local/',
      
      # For Mocking
      api_tenant_id: 'Test API Tenant ID',
      api_token: 'Test API Token',
    }
  end
  module_function :test_data

  def identity_API_data(data = test_data)
    return {
      'access' => {
        'token' => {
          'id'  => data[:api_token],
          'expires' =>'2014-02-19T01:20:15.305Z',
          'tenant'  => {
            'id'   => data[:api_tenant_id],
            'name' => data[:api_tenant_id]
          },
          'RAX-AUTH:authenticatedBy'=>['APIKEY']
        },
        'serviceCatalog'=> [
                            # WARNING: failure case tests below assume cloudBackup is ['serviceCatalog'][0]
                            {
                              'name'      => 'cloudBackup',
                              'endpoints' =>
                              [
                               # Our dummy region
                               # WARNING: tests below assume this entry first
                               {
                                 'region'    => data[:region],
                                 'tenantId'  => data[:api_tenant_id],
                                 'publicURL' => "https://#{data[:region]}.mockrcbu.local/v1.0/#{data[:api_tenant_id]}"
                               },
                               {
                                 'tenantId'  => data[:api_tenant_id],
                                 'publicURL' => "https://mockrcbu.local/v1.0/#{data[:api_tenant_id]}"
                                 # Note no region key: important case for testing.  (The API does this.)
                               },
                               # A few regions just to puff up the searched data
                               {
                                 'region'    => 'IAD',
                                 'tenantId'  => data[:api_tenant_id],
                                 'publicURL' => "https://iad.mockrcbu.local/v1.0/#{data[:api_tenant_id]}"
                               },
                               {
                                 'region'    => 'DFW',
                                 'tenantId'  => data[:api_tenant_id],
                                 'publicURL' => "https://dfw.mockrcbu.local/v1.0/#{data[:api_tenant_id]}"
                               }
                              ],
                              'type' => 'rax:backup'
                            }
                            # The rest of the catalog is omitted to keep this dataset to a resonable size.
                           ]
      }
    }
  end
  module_function :identity_API_data
    
  def mock_rcbu_API(data = test_data, identity_data = identity_API_data)
    # Set up API mocks
    # Disallow any real connections, all connections should be mocked
    WebMock.disable_net_connect!

    # Mock the identity service
    stub_request(:post, data[:api_url]).with(:body => {
                                               'auth' =>
                                               { 'RAX-KSKEY:apiKeyCredentials' =>
                                                 { 'username' => data[:api_username],
                                                   'apiKey'   => data[:api_key]
                                                 }
                                               }
                                             }.to_json,
                                             :headers => {
                                               # Headers with values we care about
                                               'Accept'       => 'application/json',
                                               'Content-Type' => 'application/json',
                                               
                                               # Headers we don't care about, but need to specify for mocking
                                               # Near as I can tell you can't specify a subset of headers to care about
                                               # So if RestClient changes the headers it sends in the future this may break.
                                               'Accept-Encoding' => /.*/,
                                               'Content-Length'  => /.*/,
                                               'User-Agent'      => /.*/
                                             }).
      to_return(:status => 200, :body => identity_data.to_json, :headers => {'Content-Type' => 'application/json'})

    # Mock the RCBU API
  end
  module_function :mock_rcbu_API
end

describe 'RcbuApiWrapper' do
  describe 'initialize' do
    before :each do
      @test_data     = RcbuApiWrapperTestHelpers.test_data
      @identity_data = RcbuApiWrapperTestHelpers.identity_API_data
      RcbuApiWrapperTestHelpers.mock_rcbu_API(@test_data, @identity_data)
    end

    it 'sets the agent_id class instance variable' do
      @test_obj = Opscode::Rackspace::CloudBackup::RcbuApiWrapper.new(@test_data[:api_username], @test_data[:api_key], @test_data[:region], @test_data[:agent_id], @test_data[:api_url])
      @test_obj.agent_id.should eql @test_data[:agent_id]
    end

    it 'sets the api_url class instance variable' do
      @test_obj = Opscode::Rackspace::CloudBackup::RcbuApiWrapper.new(@test_data[:api_username], @test_data[:api_key], @test_data[:region], @test_data[:agent_id], @test_data[:api_url])
      @test_obj.api_url.should eql @test_data[:api_url]
    end

    it 'sets the api token class instance variable' do
      @test_obj = Opscode::Rackspace::CloudBackup::RcbuApiWrapper.new(@test_data[:api_username], @test_data[:api_key], @test_data[:region], @test_data[:agent_id], @test_data[:api_url])
      @test_obj.token.should eql @test_data[:api_token]
    end
    
    it 'fails if "cloudBackup" is not in the catalog' do
      fail 'Assert error on test data: serviceCatalog order' if @identity_data['access']['serviceCatalog'][0]['name'] != 'cloudBackup'
      @identity_data['access']['serviceCatalog'][0]['name'] = 'notCloudBackup'
      RcbuApiWrapperTestHelpers.mock_rcbu_API(@test_data, @identity_data)

      expect { Opscode::Rackspace::CloudBackup::RcbuApiWrapper.new(@test_data[:api_username],
                                                                   @test_data[:api_key],
                                                                   @test_data[:region],
                                                                   @test_data[:agent_id],
                                                                   @test_data[:api_url]) }.to raise_exception
    end

    it 'fails if the region is not in the cloudBackup service catalog' do
      expect { Opscode::Rackspace::CloudBackup::RcbuApiWrapper.new(@test_data[:api_username],
                                                                   @test_data[:api_key],
                                                                   'Atlantis',
                                                                   @test_data[:agent_id],
                                                                   @test_data[:api_url]) }.to raise_exception
    end
    
    it 'sets the rcbu API URL class instance variable' do
      fail 'Assert error on test data: serviceCatalog order' if @identity_data['access']['serviceCatalog'][0]['name'] != 'cloudBackup'
      fail 'Assert error on test data: endpoint order' if @identity_data['access']['serviceCatalog'][0]['endpoints'][0]['region'] != @test_data[:region]

      @test_obj = Opscode::Rackspace::CloudBackup::RcbuApiWrapper.new(@test_data[:api_username], @test_data[:api_key], @test_data[:region], @test_data[:agent_id], @test_data[:api_url])
      @test_obj.rcbu_api_url.should eql @identity_data['access']['serviceCatalog'][0]['endpoints'][0]['publicURL']
    end
  end
end    
