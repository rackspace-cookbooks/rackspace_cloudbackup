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

require_relative '../../../libraries/MockRcbuApiWrapper.rb'

include WebMock::API

# Define the unique helper module for this test suite.
module MockRcbuApiWrapperTestHelpers
  def test_data
    return {
      api_username: 'Test API Username',
      api_key:      'Test API Key',
      region:       'TESTREGION',    # Needs to be UPCASE
      agent_id:     'TestAgentID', # I believe in the real API this needs to be an int, but our code doesn't care
      api_url:      'http://mockidentity.local/'
    }
  end
  module_function :test_data
end

describe 'MockRcbuApiWrapper' do
  describe 'initialize' do
    before :each do
      @test_data = MockRcbuApiWrapperTestHelpers.test_data
      WebMock.disable_net_connect!
      @test_obj = Opscode::Rackspace::CloudBackup::MockRcbuApiWrapper.new(@test_data[:api_username], @test_data[:api_key],
                                                                          @test_data[:region], @test_data[:agent_id], @test_data[:api_url])
    end

    it 'sets the agent_id class instance variable' do
      @test_obj.agent_id.should eql @test_data[:agent_id]
    end

    it 'sets the identity_api_url class instance variable' do
      @test_obj.identity_api_url.should eql @test_data[:api_url]
    end

    it 'sets the api token class instance variable' do
      @test_obj.token.should eql 'MockRcbuApiWrapper Test Token'
    end

    it 'sets the rcbu API URL class instance variable' do
      @test_obj.rcbu_api_url.should eql 'https://MockRcbuApiWrapper.dummy.api.local/'
    end
  end

  describe '_identity_data' do
    before :each do
      @test_data = MockRcbuApiWrapperTestHelpers.test_data
      WebMock.disable_net_connect!
      @test_obj = Opscode::Rackspace::CloudBackup::MockRcbuApiWrapper.new(@test_data[:api_username], @test_data[:api_key],
                                                                          @test_data[:region], @test_data[:agent_id], @test_data[:api_url])
    end

    it 'has none of your shennanigans' do
      expect { @test_obj._identity_data('foo', 'bar') }.to raise_exception
    end
  end

  # These are grouped because we need one to test the other.
  describe 'stateful lookup_configurations / create_config mocks: ' do
    before :each do
      @test_data = MockRcbuApiWrapperTestHelpers.test_data
      WebMock.disable_net_connect!
      @test_obj = Opscode::Rackspace::CloudBackup::MockRcbuApiWrapper.new(@test_data[:api_username], @test_data[:api_key],
                                                                          @test_data[:region], @test_data[:agent_id], @test_data[:api_url])
    end

    it 'lookup_configurations sets configurations class instance variable to [] when mock_configurations class variable is empty' do
      @test_obj.mock_configurations.should eql []
      @test_obj.lookup_configurations
      @test_obj.configurations.should eql []
    end

    it 'create_config sets BackupConfigurationId' do
      @test_obj.mock_configurations.should eql []
      test_data = { 'name' => 'dataW', 'key1' => 'dataW-1', 'key2' => 'dataW-2' }
      @test_obj.create_config(test_data)
      @test_obj.mock_configurations[0]['BackupConfigurationId'].should_not eql nil
    end

    it 'create_config adds config to mock_configurations class variable' do
      @test_obj.mock_configurations.should eql []
      test_data = { 'name' => 'dataW', 'key1' => 'dataW-1', 'key2' => 'dataW-2' }
      @test_obj.create_config(test_data)
      stored_data = @test_obj.mock_configurations[0]
      stored_data.delete('BackupConfigurationId') # Drop the key added by the mock
      stored_data.should eql test_data
    end

    it 'create_config adds unique configs to mock_configurations class variable' do
      @test_obj.mock_configurations.should eql []
      test_data = { 'name' => 'dataW', 'key1' => 'dataW-1', 'key2' => 'dataW-2' }
      10.times do
        @test_obj.create_config(test_data)
      end
      @test_obj.mock_configurations.length.should eql 10
    end

    it 'rejects data with BackupConfigurationId set' do
      test_data = { 'name' => 'dataW', 'key1' => 'dataW-1', 'key2' => 'dataW-2', 'BackupConfigurationId' => 29475 }
      expect { @test_obj.create_config(test_data) }.to raise_exception
    end

    it 'lookup_configurations sets configurations class instance variable to mock_configurations when mock_configurations class variable is not empty' do
      @test_obj.mock_configurations.should eql []
      test_data = { 'name' => 'dataW', 'key1' => 'dataW-1', 'key2' => 'dataW-2' }
      @test_obj.create_config(test_data)
      @test_obj.lookup_configurations
      @test_obj.configurations.should eql @test_obj.mock_configurations
    end
  end

  describe 'update_config' do
    before :each do
      @test_data = MockRcbuApiWrapperTestHelpers.test_data
      WebMock.disable_net_connect!
      @test_obj = Opscode::Rackspace::CloudBackup::MockRcbuApiWrapper.new(@test_data[:api_username], @test_data[:api_key],
                                                                          @test_data[:region], @test_data[:agent_id], @test_data[:api_url])
    end

    it 'fails if the config_id doesn\'t exist in mock_configurations class variable' do
      @test_obj.mock_configurations.should eql []
      expect { @test_obj.update_config(12345,  foo: 'bar') }.to raise_exception
    end

    it 'updates existing entries in the mock_configurations class variable' do
      @test_obj.mock_configurations.should eql []
      initial_data = { 'name' => 'dataI', 'key1' => 'dataI-1', 'key2' => 'dataI-2' }
      @test_obj.create_config(initial_data)

      new_data = { 'name' => 'dataN', 'key1' => 'dataN-1', 'key2' => 'dataN-2', 'BackupConfigurationId' => @test_obj.mock_configurations[0]['BackupConfigurationId'] }
      @test_obj.update_config(@test_obj.mock_configurations[0]['BackupConfigurationId'], new_data)
      @test_obj.mock_configurations[0].should eql new_data
    end

    it 'rejects changing the BackupConfigurationId' do
      @test_obj.mock_configurations.should eql []
      initial_data = { 'name' => 'dataI', 'key1' => 'dataI-1', 'key2' => 'dataI-2' }
      @test_obj.create_config(initial_data)

      new_data = { 'name' => 'dataN', 'key1' => 'dataN-1', 'key2' => 'dataN-2', 'BackupConfigurationId' => 'Bad Test ID' }
      expect { @test_obj.update_config(@test_obj.mock_configurations[0]['BackupConfigurationId'], new_data) }.to raise_exception
    end

  end
end
