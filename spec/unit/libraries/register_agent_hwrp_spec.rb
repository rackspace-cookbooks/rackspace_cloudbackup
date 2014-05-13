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

module RegisterAgentHwrpSpecHelpers
  def initialize_tests
    # This is required here as ChefSpec interferes with WebMocks, breaking tests
    # rspec does not fully reinitialize the global namespace, so anything declated outside of tests
    # shared between all tests.
    require 'chefspec_helper'
    require_relative '../../../libraries/register_agent_hwrp.rb'
    require_relative 'test_helpers.rb'
  end
  module_function :initialize_tests

  def common_new_resource_data
    return CloudBackupTestHelpers::TestResourceData.new(
                                                          name:                 'Test Name',
                                                          label:                'Test Label',
                                                          rackspace_api_key:    'Test Key',
                                                          rackspace_username:   'Test Username',
                                                          bootstrap_file_path:  'Test Bootstrap File Path'
                                                        )
  end
  module_function :common_new_resource_data

  def common_test_obj(resource_data = common_new_resource_data)
    return Chef::Provider::RackspaceCloudbackupRegisterAgent.new(resource_data, nil)
  end
  module_function :common_test_obj

  # A simple class to mock Mixlib::ShellOut for our testing
  class MixLibShellOutMock
    attr_accessor :testhook_command, :testhook_run_called

    def initialize(command)
      @testhook_command = command
      testhook_run_called = false
    end

    def run_command
      @testhook_run_called = true
    end
  end
end

describe 'rackspace_cloudbackup_register_agent_hwrp' do
  describe 'resource' do
    describe '#initialize' do
      before :each do
        RegisterAgentHwrpSpecHelpers.initialize_tests
        @test_resource = Chef::Resource::RackspaceCloudbackupRegisterAgent.new('Test Label')
      end

      it 'should have a resource name of rackspace_cloudbackup_register_agent' do
        @test_resource.resource_name.should eql :rackspace_cloudbackup_register_agent
      end

      [:register, :nothing].each do |action|
        it "should support the #{action} action" do
          @test_resource.allowed_actions.should include action
        end
      end

      it 'should should have a default :register action' do
        @test_resource.action.should eql :register
      end

      it 'should set label to the name attribute' do
        @test_resource.label.should eql 'Test Label'
      end

      it 'should default bootstrap_file_path to /etc/driveclient/bootstrap.json' do
        @test_resource.bootstrap_file_path.should eql '/etc/driveclient/bootstrap.json'
      end
    end

    { label:                'Attr Test Label',
      rackspace_api_key:    'Attr Test Key',
      rackspace_username:   'Attr Test Username',
      bootstrap_file_path:  'Attr Test Bootstrap File Path',
    }.each do |attr, value|
      describe "##{attr}" do
        before :all do
          RegisterAgentHwrpSpecHelpers.initialize_tests
          @test_resource = Chef::Resource::RackspaceCloudbackupRegisterAgent.new('Test Label')
        end

        # No nil values currently allowed, all attributes either have defaults or are required.

        it 'should set values' do
          @test_resource.send(attr, value).should eql value
        end

        it 'should get values' do
          @test_resource.send(attr).should eql value
        end
      end
    end
  end

  describe 'provider' do
    describe 'load_current_resource' do
      before :each do
        RegisterAgentHwrpSpecHelpers.initialize_tests
        @new_resource = RegisterAgentHwrpSpecHelpers.common_new_resource_data
        @test_obj = RegisterAgentHwrpSpecHelpers.common_test_obj(@new_resource)
        Opscode::Rackspace::CloudBackup.stub(:gather_bootstrap_data).with('Test Bootstrap File Path') { CloudBackupTestHelpers.valid_bootstrap_data }
        @test_obj.load_current_resource
      end

      it 'initializes current_resource to be a Chef::Resource::RackspaceCloudbackupRegisterAgent' do
        @test_obj.current_resource.should be_an_instance_of Chef::Resource::RackspaceCloudbackupRegisterAgent
      end

      it 'Sets label to new_resource.name when new_resource.label is nil' do
        @new_resource.label = nil
        @test_obj = Chef::Provider::RackspaceCloudbackupRegisterAgent.new(@new_resource, nil)
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
        RegisterAgentHwrpSpecHelpers.initialize_tests
        @new_resource = RegisterAgentHwrpSpecHelpers.common_new_resource_data
        @test_obj = RegisterAgentHwrpSpecHelpers.common_test_obj(@new_resource)
        stub_const('Mixlib::ShellOut', RegisterAgentHwrpSpecHelpers::MixLibShellOutMock)
      end

      it 'Registers the agent when IsRegistered is false' do
        Opscode::Rackspace::CloudBackup.stub(:gather_bootstrap_data).with('Test Bootstrap File Path') { { 'IsRegistered' => false } }
        @test_obj.load_current_resource
        @test_obj.new_resource.updated.should eql nil
        fail 'Failed to stub Mixlib::ShellOut' unless Mixlib::ShellOut.new(nil).is_a? RegisterAgentHwrpSpecHelpers::MixLibShellOutMock
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
        RegisterAgentHwrpSpecHelpers.initialize_tests
        @test_obj = RegisterAgentHwrpSpecHelpers.common_test_obj
      end

      it 'Does nothing' do
        @test_obj.new_resource.updated.should eql nil
        @test_obj.action_nothing
        @test_obj.new_resource.updated.should eql false
      end
    end
  end
end
