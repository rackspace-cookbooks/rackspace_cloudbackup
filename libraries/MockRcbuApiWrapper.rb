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

require_relative 'RcbuApiWrapper.rb'

module Opscode
  module Rackspace
    module CloudBackup
      class MockRcbuApiWrapper < RcbuApiWrapper
        attr_accessor :mock_configurations

        def initialize(api_username, api_key, region, agent_id, identity_api_url = 'https://identity.api.rackspacecloud.com/v2.0/tokens')
          @agent_id     = agent_id
          @identity_api_url      = identity_api_url
          @token        = 'MockRcbuApiWrapper Test Token'
          @rcbu_api_url = 'https://MockRcbuApiWrapper.dummy.api.local/'

          # Storage array for stateful mocks
          @mock_configurations = []
        end

        def _identity_data(api_username, api_key)
          fail 'Why are you calling _identity_data directly?'
        end

        def lookup_configurations
          @configurations = @mock_configurations
        end

        # Use real locate_existing_config: No code change needed
        # def locate_existing_config(label)

        def create_config(config)
          # There are more fields the user should not set, but we're not checking for them at this time.
          fail 'BackupConfigurationId should not be set by the user' unless config['BackupConfigurationId'].nil?

          # Dup the hash so we don't modify the parent
          my_config = config.dup

          # Add fields populated by the API
          my_config['BackupConfigurationId'] = _random_id
          @mock_configurations.push(my_config)
        end

        def update_config(config_id, config)
          if config.key? 'BackupConfigurationId'
            fail 'Cannot change BackupConfigurationId' unless config['BackupConfigurationId'] == config_id
          end

          # We need to get the index to change the parent data structure, so not using .find
          @mock_configurations.length.times do |i|
            if @mock_configurations[i]['BackupConfigurationId'] == config_id
              @mock_configurations[i] = config
              # Ensure the BackupConfigurationId isn't accidentially changed
              @mock_configurations[i]['BackupConfigurationId'] = config_id
              return
            end
          end

          fail 'Unable to locate BackupConfigurationId #{config_id} for update'
        end

        # Helper for testing
        def _random_id
          src = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
          return (0...10).map { src[rand(src.length)] }.join
        end
      end
    end
  end
end
