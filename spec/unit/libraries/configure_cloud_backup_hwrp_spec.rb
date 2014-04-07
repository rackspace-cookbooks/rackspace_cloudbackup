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

  def common_dummy_data
    return {
      label:                   { test_value: 'label Attribute Test Value',                   required: false, default: 'Test Label' },
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
      mock:                    { test_value: true,                                           required: false, default: false },
      rcbu_bootstrap_file:     { test_value: '/tmp/test_bootstrap_file.json',                required: false, default: '/etc/driveclient/bootstrap.json' },
    }
  end
  module_function :common_dummy_data

  def common_new_resource_data
    # Create a dummy resource set uting the common_dummy_data set already defined with valid data
    # As the common_dummy_data block contains an inner hash we need to recreate the hash as a single depth key:value pair
    # using the test_value value to pass into the TestResourceData test class.
    # We also need to add the name parameter which is not present in the dummy data set as is it handled by the provider, not the resource.
    return CloudBackupTestHelpers::TestResourceData.new(common_dummy_data.merge(common_dummy_data){ |k,v| v[:test_value] }.merge({name: 'Test Name'}))
    # Everybody got that? http://lost.cubit.net/archives/assets_c/2010/04/04122010_6x08_Spaceballs-thumb-470x258-3171.jpg
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

      ConfigureCloudBackupHwrpSpecHelpers.common_dummy_data.merge(ConfigureCloudBackupHwrpSpecHelpers.common_dummy_data){ |k,v| v[:default] }.delete_if{ |k,v| v.nil? }.each do |option, default_value|
        it "should default #{option} to #{default_value}" do
          @test_resource.send(option).should eql default_value
        end
      end
    end

    ConfigureCloudBackupHwrpSpecHelpers.common_dummy_data.each do |attr, value_data|
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

  describe 'provider' do
    describe 'load_current_resource' do
      before :each do
        ConfigureCloudBackupHwrpSpecHelpers.initialize_tests
        @new_resource = ConfigureCloudBackupHwrpSpecHelpers.common_new_resource_data
        @test_obj = ConfigureCloudBackupHwrpSpecHelpers.common_test_obj(@new_resource)
        Opscode::Rackspace::CloudBackup.stub(:gather_bootstrap_data).with(@new_resource.rcbu_bootstrap_file) { CloudBackupTestHelpers.valid_bootstrap_data }
        @test_obj.load_current_resource
      end

      it 'initializes current_resource to be a Chef::Resource::RackspaceCloudbackupConfigureCloudBackup' do
        @test_obj.current_resource.should be_an_instance_of Chef::Resource::RackspaceCloudbackupConfigureCloudBackup
      end

      it 'Sets label to new_resource.name when new_resource.label is nil' do
        @new_resource.label = nil
        @test_obj = Chef::Provider::RackspaceCloudbackupConfigureCloudBackup.new(@new_resource, nil)
        @test_obj.load_current_resource
        @test_obj.current_resource.label.should eql @new_resource.name
      end

      it 'Sets label to new_resource.label when new_resource.label is specified' do
        @test_obj.current_resource.label.should eql @new_resource.label
      end
      
      [:rackspace_api_key, :rackspace_username, :rackspace_api_region, :inclusions, :exclusions, :is_active,
       :version_retention, :frequency, :start_time_hour, :start_time_minute, :start_time_am_pm, :day_of_week_id, :hour_interval,
       :time_zone_id, :notify_recipients, :notify_success, :notify_failure, :backup_prescript, :backup_postscript, :missed_backup_action_id,
       :mock, :rcbu_bootstrap_file
      ].each do |arg|
        it "Sets #{arg} to new_resource.#{arg}" do
          @new_resource.send(arg).should_not eql nil
          @test_obj.current_resource.send(arg).should eql @new_resource.send(arg)
        end
      end

      it 'initializes api_obj' do
        @test_obj.current_resource.api_obj.should be_an_instance_of Opscode::Rackspace::CloudBackup::RcbuBackupWrapper
      end
    end

    #
    # INCOMPLETE: NEED
    # action_create
    # action_create_if_missing
    # action_nothing
  end    
end
