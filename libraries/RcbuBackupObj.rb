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

module Opscode
  module Rackspace
    module CloudBackup
      # RcbuBackupObj: Provide a object class representing a backup object in the API
      class RcbuBackupObj
        # Disable the VariableName cop which fails on SnakeCase variable names
        # This class uses the API variable naming as it is representing the API.
        # As such variable names match the API, not style best practices.
        # rubocop: disable VariableName

        attr_accessor :api_wrapper, :all_attributes, :settable_attributes, :label

        def initialize(label, api_wrapper)
          @api_wrapper = api_wrapper
          @label = label

          # Define getters
          # This must contain all the API values supported by the class, if values are omitted compare? will nto function correctly
          # Also assumed to be complete by tests.
          @all_attributes = %w(Inclusions Exclusions BackupConfigurationId MachineAgentId MachineName Datacenter Flavor IsEncrypted
                               EncryptionKey BackupConfigurationName IsActive IsDeleted VersionRetention BackupConfigurationScheduleId
                               MissedBackupActionId Frequency StartTimeHour StartTimeMinute StartTimeAmPm DayOfWeekId HourInterval
                               TimeZoneId NextScheduledRunTime LastRunTime LastRunBackupReportId NotifyRecipients NotifySuccess
                               NotifyFailure BackupPrescript BackupPostscript)
          @all_attributes.each do |arg|
            self.class.send(:define_method, arg, proc { instance_variable_get("@#{arg}") })
          end

          # Many attributes are read only and will result in an API error if a change is made to them
          # Only define setters for settible attributes
          @settable_attributes = %w(Inclusions Exclusions MachineAgentId IsActive VersionRetention
                                    Frequency StartTimeHour StartTimeMinute StartTimeAmPm DayOfWeekId HourInterval TimeZoneId
                                    NotifyRecipients NotifySuccess NotifyFailure BackupPrescript BackupPostscript MissedBackupActionId)
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

          # Inclusions and Exclusions need to be arrays
          if @Inclusions.nil?
            @Inclusions = []
          end
          if @Exclusions.nil?
            @Exclusions = []
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
            send("#{k}=", v)
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

        def compare?(other_obj)
          @all_attributes.each do |attr|
            if send(attr) != other_obj.send(attr)
              return false
            end
          end
          return true
        end

        def dup
          def _deep_copy_array(tgt)
            ret_val = []
            tgt.each do |src|
              ret_val.push(src.dup)
            end
            return ret_val
          end

          copy = super

          # Inclusions and Exclusions are arrays and are shallow copied by dup
          copy.Inclusions = _deep_copy_array(@Inclusions)
          copy.Exclusions = _deep_copy_array(@Exclusions)

          return copy
        end
      end
    end
  end
end
