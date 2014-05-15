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
#
# http://tech.yipit.com/2013/05/09/advanced-chef-writing-heavy-weight-resource-providers-hwrp/

require_relative 'gather_bootstrap_data.rb'

class Chef
  class Resource
    # Implement the rackspace_cloudbackup_register_agent resource
    class RackspaceCloudbackupRegisterAgent < Chef::Resource
      attr_accessor :agent_config
      attr_writer   :agent_config

      def initialize(name, run_context = nil)
        super
        @resource_name = :rackspace_cloudbackup_register_agent        # Bind ourselves to the name with an underscore
        @provider = Chef::Provider::RackspaceCloudbackupRegisterAgent # We need to tie to our provider
        @action = :register                                           # Default
        @allowed_actions = [:register, :nothing]

        @label = name
        @mock  = false
        @bootstrap_file_path = '/etc/driveclient/bootstrap.json'
      end

      def label(arg = nil)
        # set_or_return is a magic function from Chef that does most of the heavy lifting for attribute access.
        set_or_return(:label, arg, kind_of: String)
      end

      def rackspace_username(arg = nil)
        set_or_return(:rackspace_username, arg, kind_of: String, required: true)
      end

      def rackspace_api_key(arg = nil)
        set_or_return(:rackspace_auth_url, arg, kind_of: String, required: true)
      end

      def bootstrap_file_path(arg = nil)
        set_or_return(:bootstrap_file_path, arg, kind_of: String)
      end

      def mock(arg = nil)
        set_or_return(:mock, arg, kind_of: [TrueClass, FalseClass])
      end
    end
  end
end

class Chef
  class Provider
    # Implement the rackspace_cloudbackup_register_agent provider
    class RackspaceCloudbackupRegisterAgent < Chef::Provider
      attr_accessor :shell_cmd

      def load_current_resource
        @current_resource ||= Chef::Resource::RackspaceCloudbackupRegisterAgent.new(new_resource.name)
        [:label, :rackspace_api_key, :rackspace_username, :bootstrap_file_path, :mock].each do |arg|
          @current_resource.send(arg, new_resource.send(arg))
        end

        @current_resource.agent_config = Opscode::Rackspace::CloudBackup.gather_bootstrap_data(@current_resource.bootstrap_file_path)
        fail 'Failed to read agent configuration' if @current_resource.agent_config.nil?

        @current_resource
      end

      def action_register
        case @current_resource.agent_config['IsRegistered']
        when false
          if @current_resource.mock
            # Mocking, don't register
            Chef::Log.warn('WARNING: Skipping registration due to mock = true')
            new_resource.updated_by_last_action(true)
          else
            cmd_str = "driveclient -c -k '#{@current_resource.rackspace_api_key}' -u '#{@current_resource.rackspace_username}'"
            # This is a class instance variable to expose it for testing.  It allows Mixlib::ShellOut to be mocked and then probed via a getter
            @shell_cmd = Mixlib::ShellOut.new(cmd_str)
            @shell_cmd.run_command
            if @shell_cmd.status.exitstatus == 0
              new_resource.updated_by_last_action(true)
            else
              fail "Failed to register the agent! 'driveclient -c' returned #{@shell_cmd.status.exitstatus}"
            end
          end

        when true
          new_resource.updated_by_last_action(false)
        else
          fail "Rackspace CloudBackup Agent registration in unknown state: #{@current_resource.agent_config['IsRegistered']}"
        end
      end

      def action_nothing
        new_resource.updated_by_last_action(false)
      end
    end
  end
end
