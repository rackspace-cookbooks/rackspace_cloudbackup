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
      def gather_bootstrap_data(bootstrap_file)
        begin
          bootstrap_raw_data = open(bootstrap_file).read
        rescue
          Chef::Log.fatal("Error reading #{bootstrap_file}")
          return nil
        end

        begin
          bootstrap_data = JSON.parse(bootstrap_raw_data)
        rescue
          Chef::Log.fatal("Error parsing #{bootstrap_file}")
          return nil
        end

        return bootstrap_data
      end
      module_function :gather_bootstrap_data

      class RcbuApiWrapper
        attr_accessor :token, :rcbu_api_url, :agent_id, :configurations
        
        def initialize(api_username, api_key, region, agent_id)
          @agent_id = agent_id

          identity = identity_data(api_username, api_key)
          @token = identity['access']['token']['id']
          
          backup_catalog = identity['access']['serviceCatalog'].find { |c| c['name'] == "cloudBackup" }
          fail 'Opscode::Rackspace::CloudBackup::RcbuBinding.initialize: Unable to locate cloudBackup service catalog' if backup_catalog.nil?
          
          region.upcase!
          backup_catalog_region = backup_catalog['endpoints'].find { |e| e['region'] == region }
          fail "Opscode::Rackspace::CloudBackup::RcbuBinding.initialize: Unable to locate CloudBackup details from service catalog for region #{region}" if backup_catalog_region.nil?
          @rcbu_api_url = backup_catalog_region['publicURL']
          fail "Opscode::Rackspace::CloudBackup::RcbuBinding.initialize: Unable to locate CloudBackup API URL from service catalog for region #{region}" if @rcbu_api_url.nil?
        end
        
        def identity_data(api_username, api_key, api_url = 'https://identity.api.rackspacecloud.com/v2.0/tokens')
          req = { 'auth' =>
            { 'RAX-KSKEY:apiKeyCredentials' =>
              { 'username' => api_username,
                'apiKey'   => api_key
              }
            }
          }
          
          begin
            return JSON.parse(RestClient.post(api_url, req.to_json, { :content_type => :json, :accept => :json}))
          rescue
            fail 'Opscode::Rackspace::CloudBackup::RcbuBinding.identity_data: Unable to gather Rackspace identity data'
          end
        end
        
        def lookup_configurations()
          @configurations = JSON.parse(RestClient.get("#{@rcbu_api_url}/backup-configuration/system/#{@agent_id}",
                                                      { 'Content-Type' => :json, 'X-Auth-Token' => @token }))
        end

        def locate_existing_config(label)
          unless @configurations.nil?
            config = @configurations.find { |c| c['BackupConfigurationName'] == label }
            unless config.nil?
              return config
            end
          end
          
          lookup_configurations()
          @configurations.find { |c| c['BackupConfigurationName'] == label }
        end
          
        def create_config(config)
          RestClient.post("#{@rcbu_api_url}/backup-configuration/",
                          config.to_json,
                          { 'Content-Type' => :json, 'X-Auth-Token' => @token })
        end

        def update_config(config_id, config)
          RestClient.put("#{@rcbu_api_url}/backup-configuration/#{config_id}",
                         config.to_json,
                         { 'Content-Type' => :json, 'X-Auth-Token' => @token })
        end
      end

      class RcbuBackupObj
        attr_accessor :api_wrapper, :all_attributes, :settable_attributes

        def initialize(label, api_wrapper)
          @api_wrapper = api_wrapper
          @label = label
          
          # Define getters
          @all_attributes = ["Inclusions", "Exclusions", "BackupConfigurationId", "MachineAgentId", "MachineName", "Datacenter", "Flavor", "IsEncrypted",
                             "EncryptionKey", "BackupConfigurationName", "IsActive", "IsDeleted", "VersionRetention", "BackupConfigurationScheduleId",
                             "MissedBackupActionId", "Frequency", "StartTimeHour", "StartTimeMinute", "StartTimeAmPm", "DayOfWeekId", "HourInterval",
                             "TimeZoneId", "NextScheduledRunTime", "LastRunTime", "LastRunBackupReportId", "NotifyRecipients", "NotifySuccess",
                             "NotifyFailure", "BackupPrescript", "BackupPostscript"]
          @all_attributes.each do |arg|
            self.class.send(:define_method, arg, proc { instance_variable_get("@#{arg}") })
          end

          @settable_attributes = ["Inclusions", "Exclusions", "MachineAgentId", "IsActive", "VersionRetention",
                                  "Frequency", "StartTimeHour", "StartTimeMinute", "StartTimeAmPm", "DayOfWeekId", "HourInterval", "TimeZoneId",
                                  "NotifyRecipients", "NotifySuccess", "NotifyFailure", "BackupPrescript", "BackupPostscript", "MissedBackupActionId"]
          # Define Setters
          @settable_attributes.each do |arg|
            self.class.send(:define_method, "#{arg}=", proc { |x| instance_variable_set("@#{arg}", x) })
          end

          @BackupConfigurationName = label
          load

          # Ensure @MachineAgentId is set for new configs, as we pass it in here
          if @MachineAgentId.nil?
            @MachineAgentId = @api_wrapper.agent_id
          end
        end
        
        def load
          # Load existing configuration data
          current_config = @api_wrapper.locate_existing_config(@label)
          unless current_config.nil?
            current_config.each do |k, v|
              instance_variable_set("@#{k}", v)
            end
          end
        end

        def update(options = {})
          options.each do |k, v|
            self.send("#{k}=", v)
          end
        end

        def to_hash(target_attributes = @all_attributes)
          opt_hash = {}
          target_attributes.each do |arg|
            opt_hash[arg] = instance_variable_get("@#{arg}")
          end
          opt_hash
        end
        
        def save
          # BackupConfigurationName is required, but is not desirable as a setter as it is the UID for the class instance
          opt_hash = to_hash(@settable_attributes + ['BackupConfigurationName'])
          if @BackupConfigurationId.nil?
            @api_wrapper.create_config(opt_hash)
            load
          else
            @api_wrapper.update_config(@BackupConfigurationId, opt_hash)
          end
          
          return self
        end
      end
              
    end
  end
end
