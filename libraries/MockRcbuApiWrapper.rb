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

require 'json'
require 'rest_client'

module Opscode
  module Rackspace
    module CloudBackup
      class MockRcbuApiWrapper
        attr_accessor :token, :rcbu_api_url, :agent_id, :configurations, :api_url, :mock_configurations

        def initialize(api_username, api_key, region, agent_id, api_url = 'https://identity.api.rackspacecloud.com/v2.0/tokens')
          @agent_id     = agent_id
          @api_url      = api_url
          @token        = 'MockRcbuApiWrapper Test Token'
          @rcbu_api_url = 'https://MockRcbuApiWrapper.dummy.api.local/'

          # Storage array for stateful mocks
          @mock_configurations = []
        end

        def _identity_data(api_username, api_key)
          fail "Why are you calling _identity_data directly?"
        end

        def lookup_configurations
          if @mock_configurations.length == 0
            @configurations = nil
          else
            @configurations = @mock_configurations
          end
        end

        def locate_existing_config(label)
          unless @configurations.nil?
            config = @configurations.find { |c| c['BackupConfigurationName'] == label }
            unless config.nil?
              return config
            end
          end

          lookup_configurations
          @configurations.find { |c| c['BackupConfigurationName'] == label }
        end

        def create_config(config)
          @mock_configurations.push(config)
        end

        def update_config(config_id, config)
          # We need to get the index to change the parent data structure, so not using .find
          @mock_configurations.length.times do |i|
            if @mock_configurations[i]['BackupConfigurationId'] == config_id
              @mock_configurations[i] = config
              return
            end
          end
            
          fail 'Unable to locate BackupConfigurationId #{config_id} for update'            
        end
      end
    end
  end
end
