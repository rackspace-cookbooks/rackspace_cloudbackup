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


module ConfigureCloudBackupHwrpSpecHelpers
  def initialize_tests
    # This is required here as ChefSpec interferes with WebMocks, breaking tests
    # rspec does not fully reinitialize the global namespace, so anything declared outside of tests
    # shared between all tests.
    require 'chefspec_helper'
    require_relative '../../../libraries/configure_cloud_backup_hwrp.rb'
    require_relative 'test_helpers.rb'
  end
  module_function :initialize_tests

  def common_new_resource_data
    return CloudBackupTestHelpers::TestResourceData.new({
                                                          name:                 'Test Name',
                                                          label:                'Test Label',
                                                          rackspace_api_key:    'Test Key',
                                                          rackspace_username:   'Test Username',
                                                          bootstrap_file_path:  'Test Bootstrap File Path',
                                                        })
  end
  module_function :common_new_resource_data

  def common_test_obj(resource_data = common_new_resource_data)
    return Chef::Provider::RackspaceCloudbackupConfigureCloudBackup.new(resource_data, nil)
  end
  module_function :common_test_obj

end


describe 'rackspace_cloudbackup_configure_cloud_backup_hwrp' do
  describe 'resource' do
    describe '#initialize' do
      before :each do
        ConfigureCloudBackupHwrpSpecHelpers.initialize_tests
        @test_resource = Chef::Resource::RackspaceCloudbackupConfigureCloudBackup.new('Test Label')
      end

      it 'should have a resource name of rackspace_cloudbackup_configure_cloud_backup' do
        @test_resource.resource_name.should eql :rackspace_cloudbackup_configure_cloud_backup
      end

      [:create, :create_if_missing, :nothing].each do |action|
        it "should support the #{action} action" do
          @test_resource.allowed_actions.should include action
        end
      end

      it 'should should have a default :register action' do
        @test_resource.action.should eql :create
      end

      it 'should set label to the name attribute' do
        @test_resource.label.should eql 'Test Label'
      end

      { is_active: true,
        missed_backup_action_id: 1,
        notify_success: false,
        notify_failure: true,
        time_zone_id: 'UTC'}.each do |option, default_value|
        it "should default #{option} to #{default_value}" do
          @test_resource.send(option).should eql default_value
        end
      end
    end
    
    { label:                   { test_value: 'label Attribute Test Value',                   required: false, default: 'Test Label' },
      rackspace_username:      { test_value: 'rackspace_username Attribute Test Value',      required: true,  default: nil },
      rackspace_api_key:       { test_value: 'rackspace_api_key Attribute Test Value',       required: true,  default: nil },
      rackspace_api_region:    { test_value: 'rackspace_api_region Attribute Test Value',    required: true,  default: nil },
      inclusions:              { test_value: ['inclusions Attribute Test Value'],            required: true,  default: nil },
      exclusions:              { test_value: ['exclusions Attribute Test Value'],            required: false, default: nil },
      is_active:               { test_value: false,                                          required: false, default: true },
      version_retention:       { test_value: 8765,                                           required: true,  default: nil },
      frequency:               { test_value: 'frequency Attribute Test Value',               required: false, default: nil },
      start_time_hour:         { test_value: 1234,                                           required: false, default: nil },
      start_time_minute:       { test_value: 2345,                                           required: false, default: nil },
      start_time_am_pm:        { test_value: 3456,                                           required: false, default: nil },
      day_of_week_id:          { test_value: 4567,                                           required: false, default: nil },
      hour_interval:           { test_value: 5678,                                           required: false, default: nil },
      time_zone_id:            { test_value: 'time_zone_id Attribute Test Value',            required: false, default: 'UTC' },
      notify_recipients:       { test_value: 'notify_recipients Attribute Test Value',       required: true,  default: nil },
      notify_success:          { test_value: true,                                           required: false, default: false },
      notify_failure:          { test_value: false,                                          required: false, default: true },
      backup_prescript:        { test_value: 'backup_prescript Attribute Test Value',        required: false, default: nil },
      backup_postscript:       { test_value: 'backup_postscript Attribute Test Value',       required: false, default: nil },
      missed_backup_action_id: { test_value: 7654,                                           required: false, default: 1 },
    }.each do |attr, value_data|
      describe "##{attr}" do
        before :all do
          ConfigureCloudBackupHwrpSpecHelpers.initialize_tests
          @test_resource = Chef::Resource::RackspaceCloudbackupConfigureCloudBackup.new('Test Label')
          fail 'Test sanity failed: default value matches test value' if value_data[:test_value] == value_data[:default]
        end

        if value_data[:required]
          it 'should raise an exception when the getter is called without being set' do
            expect { @test_resource.send(attr) }.to raise_exception
          end
        else
          it 'should initially return the default value' do
            @test_resource.send(attr).should eql value_data[:default]
          end
        end         

        it 'should set values' do
          @test_resource.send(attr, value_data[:test_value]).should eql value_data[:test_value]
        end

        it 'should get values' do
          @test_resource.send(attr).should eql value_data[:test_value]
        end
      end
    end
  end
=begin
  describe 'provider' do
    describe 'load_current_resource' do
      before :each do
        ConfigureCloudBackupHwrpSpecHelpers.initialize_tests
        @new_resource = ConfigureCloudBackupHwrpSpecHelpers.common_new_resource_data
        @test_obj = ConfigureCloudBackupHwrpSpecHelpers.common_test_obj(@new_resource)
        Opscode::Rackspace::CloudBackup.stub(:gather_bootstrap_data).with('Test Bootstrap File Path') { CloudBackupTestHelpers.valid_bootstrap_data }
        @test_obj.load_current_resource
      end

      it 'initializes current_resource to be a Chef::Resource::RackspaceCloudbackupConfigureCloudBackup' do
        @test_obj.current_resource.should be_an_instance_of Chef::Resource::RackspaceCloudbackupConfigureCloudBackup
      end

      it 'Sets label to new_resource.name when new_resource.label is nil' do
        @new_resource.label = nil
        @test_obj = Chef::Provider::RackspaceCloudbackupConfigureCloudBackup.new(@new_resource, nil)
        @test_obj.load_current_resource
        @test_obj.current_resource.label.should eql 'Test Name'
      end

      it 'Sets label to new_resource.label when new_resource.label is specified' do
        @test_obj.current_resource.label.should eql 'Test Label'
      end

      [:rackspace_api_key, :rackspace_username, :bootstrap_file_path].each do |arg|
        it "Sets #{arg} to new_resource.#{arg}" do
          @new_resource.send(arg).should_not eql nil
          @test_obj.current_resource.send(arg).should eql @new_resource.send(arg)
        end
      end

      it 'loads the bootstrap configuration' do
        @test_obj.current_resource.agent_config.should eql CloudBackupTestHelpers.valid_bootstrap_data
      end
    end

    describe 'action_register' do
      before :each do
        ConfigureCloudBackupHwrpSpecHelpers.initialize_tests
        @new_resource = ConfigureCloudBackupHwrpSpecHelpers.common_new_resource_data
        @test_obj = ConfigureCloudBackupHwrpSpecHelpers.common_test_obj(@new_resource)
        stub_const('Mixlib::ShellOut', ConfigureCloudBackupHwrpSpecHelpers::MixLibShellOutMock)
      end

      it 'Registers the agent when IsRegistered is false' do
        Opscode::Rackspace::CloudBackup.stub(:gather_bootstrap_data).with('Test Bootstrap File Path') { { 'IsRegistered' => false } }
        @test_obj.load_current_resource
        @test_obj.new_resource.updated.should eql nil
        fail 'Failed to stub Mixlib::ShellOut' unless Mixlib::ShellOut.new(nil).is_a? ConfigureCloudBackupHwrpSpecHelpers::MixLibShellOutMock
        @test_obj.action_register
        @test_obj.new_resource.updated.should eql true
        @test_obj.shell_cmd.testhook_command.should eql "driveclient -c -k '#{@new_resource.rackspace_api_key}' -u '#{@new_resource.rackspace_username}'"
        @test_obj.shell_cmd.testhook_run_called.should eql true
      end

      it 'Does Nothing when IsRegistered is true' do
        Opscode::Rackspace::CloudBackup.stub(:gather_bootstrap_data).with('Test Bootstrap File Path') { { 'IsRegistered' => true } }
        @test_obj.load_current_resource
        @test_obj.new_resource.updated.should eql nil
        @test_obj.action_register
        @test_obj.new_resource.updated.should eql false
      end

      it 'Errors when IsRegistered is invalid' do
        Opscode::Rackspace::CloudBackup.stub(:gather_bootstrap_data).with('Test Bootstrap File Path') { { 'IsRegistered' => 'Toublecain' } }
        @test_obj.load_current_resource
        expect { @test_obj.action_register }.to raise_exception
      end

      end

    describe 'action_nothing' do
      before :each do
        ConfigureCloudBackupHwrpSpecHelpers.initialize_tests
        @test_obj = ConfigureCloudBackupHwrpSpecHelpers.common_test_obj
      end

      it 'Does nothing' do
        @test_obj.new_resource.updated.should eql nil
        @test_obj.action_nothing
        @test_obj.new_resource.updated.should eql false
      end
    end
  end
=end
end
