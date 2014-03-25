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

require_relative '../../../libraries/RcbuBackupWrapper.rb'

module RcbuBackupWrapperTestHelpers
  def dummy_bootstrap_data
    return {
      'TestData' => true, # A dummy test key
      'AgentId'  => 'Test Agent ID'
    }
  end
  module_function :dummy_bootstrap_data

  def load_backup_config_stub(rcbu_bootstrap_file)
    # Merge in the argument so we can test for it
    return dummy_bootstrap_data.merge({'BootstrapFile' => rcbu_bootstrap_file})
  end
  module_function :load_backup_config_stub

  def get_backup_obj_stub(api_username, api_key, region)
    return "STUB: ARGS: #{api_username}, #{api_key}, #{region}"
  end
  module_function :get_backup_obj_stub
end

describe 'RcbuBackupWrapper' do
  describe 'initialize' do
    before :each do
      # Stub _load_backup_config and _get_backup_obj, they will be tested separately.
      Opscode::Rackspace::CloudBackup::RcbuBackupWrapper.any_instance.stub(:_load_backup_config) do |arg|
        RcbuBackupWrapperTestHelpers.load_backup_config_stub(arg)
      end

      Opscode::Rackspace::CloudBackup::RcbuBackupWrapper.any_instance.stub(:_get_backup_obj) do |arg1, arg2, arg3|
        RcbuBackupWrapperTestHelpers.get_backup_obj_stub(arg1, arg2, arg3)
      end

      @test_obj = Opscode::Rackspace::CloudBackup::RcbuBackupWrapper.new('Test Username', 'Test Key', 'Test Region', 'Test Label', 'Test Mocking', 'Test Bootstrap File')
    end

    it 'sets the mocking variable' do
      @test_obj.mocking.should eql 'Test Mocking'
    end

    it 'sets the agent_config variable' do
      @test_obj.agent_config.should eql RcbuBackupWrapperTestHelpers.load_backup_config_stub('Test Bootstrap File')
    end

    it 'sets the backup_obj variable' do
      @test_obj.backup_obj.should eql RcbuBackupWrapperTestHelpers.get_backup_obj_stub('Test Username', 'Test Key', 'Test Region')
    end

    it 'sets the direct_name_map variable' do
      # Don't bother checking the exact content, just check that it is set
      @test_obj.direct_name_map.should be_an_instance_of Hash
    end
  end

  describe '_load_backup_config' do
    it 'fails when Opscode::Rackspace::CloudBackup.gather_bootstrap_data returns nil' do
      Opscode::Rackspace::CloudBackup.stub(:gather_bootstrap_data).and_return(nil)
      expect { Opscode::Rackspace::CloudBackup::RcbuBackupWrapper._load_backup_config(nil) }.to raise_exception
    end

    it 'fails when Opscode::Rackspace::CloudBackup.gather_bootstrap_data is missing AgentId' do
      Opscode::Rackspace::CloudBackup.stub(:gather_bootstrap_data).and_return({'foo' => 'bar'})
      expect { Opscode::Rackspace::CloudBackup::RcbuBackupWrapper._load_backup_config(nil) }.to raise_exception
    end
    
    it 'returns data from Opscode::Rackspace::CloudBackup.gather_bootstrap_data when data is valid' do
      Opscode::Rackspace::CloudBackup.stub(:gather_bootstrap_data) do |arg|
        RcbuBackupWrapperTestHelpers.load_backup_config_stub(arg)
      end
      
      Opscode::Rackspace::CloudBackup::RcbuBackupWrapper._load_backup_config('Test Bootstrap File').should eql RcbuBackupWrapperTestHelpers.load_backup_config_stub('Test Bootstrap File')
    end
  end

end
