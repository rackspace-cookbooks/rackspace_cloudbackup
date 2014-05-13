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

require 'rspec_helper'
require 'webmock/rspec'

require_relative '../../../libraries/RcbuApiWrapper.rb'

include WebMock::API

module RcbuApiWrapperTestHelpers
  def test_data
    return {
      api_username: 'Test API Username',
      api_key:      'Test API Key',
      region:       'TESTREGION',    # Needs to be UPCASE
      agent_id:     'TestAgentID', # I believe in the real API this needs to be an int, but our code doesn't care
      api_url:      'http://mockidentity.local/',
      
      # For Mocking
      api_tenant_id: 'TestAPITenantID', # Used in URL
      api_token: 'Test API Token',

      # For write tests
      dummy_write_data: { 'name' => 'dataW', 'key1' => 'dataW-1', 'key2' => 'dataW-2'},
      dummy_config_id:  'TestConfigurationID'
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

  def rcbu_API_configurations_data
    # As we're just testing API calls and not the use of the data return dummy data
    base_dataset = []
    retVal = []
    3.times do |x|
      base_dataset.push({ 'name' => "data#{x}", 'key1' => "data#{x}-1", 'key2' => "data#{x}-2", 'BackupConfigurationName' => "data#{x}"})
    end
    retVal.push(base_dataset)
    
    base_dataset = []
    3.times do |y|
      # Intentionally remove data0 so we can tell which set the data came from.
      x = y + 1
      base_dataset.push({ 'name' => "data#{x}", 'key1' => "data#{x}-1", 'key2' => "data#{x}-2", 'BackupConfigurationName' => "data#{x}"})
    end
    retVal.push(base_dataset)
    
    return retVal
  end
  module_function :rcbu_API_configurations_data

  def mock_identity_API(data = test_data, identity_data = identity_API_data)
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
  end
  module_function :mock_identity_API

  def mock_rcbu_backup_configuration_api(data = test_data, configurations_data = rcbu_API_configurations_data)
    # Mock get for lookup_configurations
    stub_request(:get, "https://#{data[:region]}.mockrcbu.local/v1.0/#{data[:api_tenant_id]}/backup-configuration/system/#{data[:agent_id]}").
      with(:headers => {
           # Headers with values we care about
           'Accept'       => 'application/json',
           'X-Auth-Token' => data[:api_token],
           
           # Headers we don't care about, but need to specify for mocking
           'Accept-Encoding' => /.*/,
           'User-Agent'      => /.*/
           }).
      # Overload the data response for subsequent call testing
      to_return({ :status => 200, :body => rcbu_API_configurations_data[0].to_json, :headers => {'Content-Type' => 'application/json'} },
                { :status => 200, :body => rcbu_API_configurations_data[1].to_json, :headers => {'Content-Type' => 'application/json'} },
                { :status => 400, :body => '', :headers => {}})

    # Mock post for create_config
    stub_request(:post, "https://#{data[:region]}.mockrcbu.local/v1.0/#{data[:api_tenant_id]}/backup-configuration/").
      with(:body => data[:dummy_write_data],
           :headers => {
             # Headers with values we care about
             'Content-Type' => 'application/json',
             'X-Auth-Token' => data[:api_token],
           
             # Headers we don't care about, but need to specify for mocking
             'Accept'          => /.*/,
             'Accept-Encoding' => /.*/,
             'Content-Length'  => /.*/,
             'User-Agent'      => /.*/
           }).
      # Overload the data response for bad call testing
      to_return({:status => 200, :body => '', :headers => {}},
                {:status => 400, :body => '', :headers => {}})

    # Mock put for update_config
    stub_request(:put, "https://#{data[:region]}.mockrcbu.local/v1.0/#{data[:api_tenant_id]}/backup-configuration/#{data[:dummy_config_id]}").
      with(:body => data[:dummy_write_data],
           :headers => {
             # Headers with values we care about
             'Content-Type' => 'application/json',
             'X-Auth-Token' => data[:api_token],
           
             # Headers we don't care about, but need to specify for mocking
             'Accept'          => /.*/,
             'Accept-Encoding' => /.*/,
             'Content-Length'  => /.*/,
             'User-Agent'      => /.*/
           }).
      # Overload the data response for bad call testing
      to_return({:status => 200, :body => '', :headers => {}},
                {:status => 400, :body => '', :headers => {}})
    
  end
  module_function :mock_rcbu_backup_configuration_api
end

describe 'RcbuApiWrapper' do
  describe 'initialize' do
    before :each do
      @test_data     = RcbuApiWrapperTestHelpers.test_data
      @identity_data = RcbuApiWrapperTestHelpers.identity_API_data
      RcbuApiWrapperTestHelpers.mock_identity_API(@test_data, @identity_data)
    end

    it 'sets the agent_id class instance variable' do
      @test_obj = Opscode::Rackspace::CloudBackup::RcbuApiWrapper.new(@test_data[:api_username], @test_data[:api_key], @test_data[:region], @test_data[:agent_id], @test_data[:api_url])
      @test_obj.agent_id.should eql @test_data[:agent_id]
    end

    it 'sets the identity_api_url class instance variable' do
      @test_obj = Opscode::Rackspace::CloudBackup::RcbuApiWrapper.new(@test_data[:api_username], @test_data[:api_key], @test_data[:region], @test_data[:agent_id], @test_data[:api_url])
      @test_obj.identity_api_url.should eql @test_data[:api_url]
    end

    it 'sets the api token class instance variable' do
      @test_obj = Opscode::Rackspace::CloudBackup::RcbuApiWrapper.new(@test_data[:api_username], @test_data[:api_key], @test_data[:region], @test_data[:agent_id], @test_data[:api_url])
      @test_obj.token.should eql @test_data[:api_token]
    end
    
    it 'fails if "cloudBackup" is not in the catalog' do
      fail 'Assert error on test data: serviceCatalog order' if @identity_data['access']['serviceCatalog'][0]['name'] != 'cloudBackup'
      @identity_data['access']['serviceCatalog'][0]['name'] = 'notCloudBackup'
      RcbuApiWrapperTestHelpers.mock_identity_API(@test_data, @identity_data)

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

  describe 'lookup_configurations' do
    before :each do
      @test_data     = RcbuApiWrapperTestHelpers.test_data
      @identity_data = RcbuApiWrapperTestHelpers.identity_API_data
      @configurations_data = RcbuApiWrapperTestHelpers.rcbu_API_configurations_data
      RcbuApiWrapperTestHelpers.mock_identity_API(@test_data, @identity_data)
      RcbuApiWrapperTestHelpers.mock_rcbu_backup_configuration_api(@test_data, @configurations_data)
      @test_obj = Opscode::Rackspace::CloudBackup::RcbuApiWrapper.new(@test_data[:api_username], @test_data[:api_key], @test_data[:region], @test_data[:agent_id], @test_data[:api_url])
    end
    
    it 'sets the configurations class instance variable' do
      @test_obj.configurations.should eql nil
      @test_obj.lookup_configurations
      @test_obj.configurations.should eql @configurations_data[0]
    end

    # This is really testing the test, but it is important to verify as locate_existing_config() tests depend on this behavior.
    it 'updates the configurations class instance variable' do
      # Rehash of the last test to get to proper state
      @test_obj.configurations.should eql nil
      @test_obj.lookup_configurations
      @test_obj.configurations.should eql @configurations_data[0]

      # Content of the new test
      @test_obj.lookup_configurations
      @test_obj.configurations.should eql @configurations_data[1]
    end

    it 'fails on bad response code' do
      @test_obj.configurations.should eql nil
      @test_obj.lookup_configurations
      @test_obj.configurations.should eql @configurations_data[0]
      @test_obj.lookup_configurations
      @test_obj.configurations.should eql @configurations_data[1]
      expect { @test_obj.lookup_configurations }.to raise_error
    end
  end

  describe 'locate_existing_config' do 
    before :each do
      @test_data     = RcbuApiWrapperTestHelpers.test_data
      @identity_data = RcbuApiWrapperTestHelpers.identity_API_data
      @configurations_data = RcbuApiWrapperTestHelpers.rcbu_API_configurations_data
      RcbuApiWrapperTestHelpers.mock_identity_API(@test_data, @identity_data)
      RcbuApiWrapperTestHelpers.mock_rcbu_backup_configuration_api(@test_data, @configurations_data)
      @test_obj = Opscode::Rackspace::CloudBackup::RcbuApiWrapper.new(@test_data[:api_username], @test_data[:api_key], @test_data[:region], @test_data[:agent_id], @test_data[:api_url])
    end
   
    it 'looks up configurations when configurations class instance variable is nil' do
      @test_obj.configurations.should eql nil
      @test_obj.locate_existing_config('data0').should eql @configurations_data[0][0]
    end

    it 'only looks up configurations once when configurations class instance variable is nil' do
      @test_obj.configurations.should eql nil
      # This relies on the mock returning more data on the second call: data4 shouldn't be present in the first lookup
      @test_obj.locate_existing_config('data3').should eql nil
    end

    it 'returns data from configurations class instance variable when configurations is not nil' do
      @test_obj.configurations.should eql nil
      @test_obj.lookup_configurations
      @test_obj.configurations.should eql @configurations_data[0]

      # This relies on the mock returning different data on the second call: data0 shouldn't be present in the second lookup
      # so this should expose unnecessairy lookups
      @test_obj.locate_existing_config('data0').should eql @configurations_data[0][0]
    end

    it 'performs a fresh lookup if desired value is not in configurations class instance variable' do
      @test_obj.configurations.should eql nil
      @test_obj.lookup_configurations
      @test_obj.configurations.should eql @configurations_data[0]
      
      @test_obj.locate_existing_config('data3').should eql @configurations_data[1][2]
    end

    it 'returns nil on no match' do
      @test_obj.locate_existing_config('bogus').should eql nil
    end
  end

  describe 'config writer' do
    before :each do
      @test_data     = RcbuApiWrapperTestHelpers.test_data
      @identity_data = RcbuApiWrapperTestHelpers.identity_API_data
      @configurations_data = RcbuApiWrapperTestHelpers.rcbu_API_configurations_data
      RcbuApiWrapperTestHelpers.mock_identity_API(@test_data, @identity_data)
      RcbuApiWrapperTestHelpers.mock_rcbu_backup_configuration_api(@test_data, @configurations_data)
      @test_obj = Opscode::Rackspace::CloudBackup::RcbuApiWrapper.new(@test_data[:api_username], @test_data[:api_key], @test_data[:region], @test_data[:agent_id], @test_data[:api_url])
    end

    it 'create_config posts the configuration to the API' do
      @test_obj.create_config(@test_data[:dummy_write_data])
    end

    it 'create_config fails on non-200 status code' do
      # Like the get above we're relying on differing data for subsequent calls
      @test_obj.create_config(@test_data[:dummy_write_data])
      expect { @test_obj.create_config(@test_data[:dummy_write_data]) }.to raise_exception
    end

    it 'update_config puts the configuration to the API' do
      @test_obj.update_config(@test_data[:dummy_config_id], @test_data[:dummy_write_data])
    end

    it 'update_config fails on non-200 status code' do
      # Like the get above we're relying on differing data for subsequent calls
      @test_obj.update_config(@test_data[:dummy_config_id], @test_data[:dummy_write_data])
      expect { @test_obj.update_config(@test_data[:dummy_config_id], @test_data[:dummy_write_data]) }.to raise_exception
    end
  end 
end    
