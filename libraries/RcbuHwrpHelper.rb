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

require_local 'RcbuApiWrapper.rb'
require_local 'RcbuBackupObj.rb'

module Opscode
  module Rackspace
    module CloudBackup
      class RcbuHwrpHelper
        def initialize(api_username, api_key, region, agent_id, backup_api_label)
          # This class intentionally uses a class variable to share API tokens and cached data connections across class instances
          # The class variable is guarded by use of the RcbuCache class which ensures proper connections are utilized
          #    across different class instances.
          # Basically we're in a corner case where class variables are called for.
          # rubocop:disable ClassVars
          unless defined? @@api_obj_cache
            @@api_obj_cache = Opscode::Rackspace::CloudBackup::RcbuCache.new(4)
          end
          api_obj = @@api_obj_cache.get(api_username, api_key, region, agent_id)
          # rubocop:enable ClassVars

          if api_obj.nil?
            api_obj = Opscode::Rackspace::CloudBackup::RcbuApiWrapper.new(api_username, api_key, region, agent_id)
            Chef::Log.debug("Opscode::Rackspace::CloudBackup::RcbuHwrpHelper.initialize: Opened new API Object")
          else
            Chef::Log.debug("Opscode::Rackspace::CloudBackup::RcbuHwrpHelper.initialize: Reusing existing API Object")
          end

          @backup_obj = Opscode::Rackspace::CloudBackup::RcbuBackupObj.new(backup_api_label, api_obj)

          # Mapping of the HWRP option names to the BackupObj (API) names that map directly (no mods)
          @direct_name_map = {
            is_active:         'IsActive',
            version_retention: 'VersionRetention',
            frequency:         'Frequency',
            start_time_hour:   'StartTimeHour',
            start_time_minute: 'StartTimeMinute',
            start_time_am_pm:  'StartTimeAmPm',
            day_of_week_id:    'DayOfWeekId',
            hour_interval:     'HourInterval',
            time_zone_id:      'TimeZoneId',
            notify_recipients: 'NotifyRecipients',
            notify_success:    'NotifySuccess',
            notify_failure:    'NotifyFailure',
            backup_prescript:  'BackupPrescript',
            backup_postscript: 'BackupPostscript',
            missed_backup_action_id: 'MissedBackupActionId'
          }
            
        end

        def _path_mapper(data_array, target)
          data_array.each do |dir|
            api_dir = target.find { |i| i['FilePath'] == dir }
            if api_dir.nil?
              # We assume all the arguments are directories
              target.push(FilePath: dir, FileItemType: 'Folder')
            else
              # Don't waste the cycle checking this, either it is wrong and needs to be set or this will have no effect
              api_dir.FileItemType = 'Folder'
            end
          end
        end

        def update(options = {})
          comp_obj = @backup_obj.dup

          options.each do |key, value|
            # Map in the objects with 1-1 mapping
            if @direct_name_map.key?(key)
              @backup_obj.send("#{@direct_name_map[key]}=", value)
              next
            end

            # Non-direct maps
            case key
            when inclusions
              # Inclusions is not quite 1-1 as the API adds extra fields and IDs, and requires a type value
              _path_mapper(values, @backup_obj.Inclusions)
              
            when exclusions
              # Exclusions is like Inclusions
              _path_mapper(values, @backup_obj.Exclusions)

            else
              raise "Opscode::Rackspace::CloudBackup::RcbuHwrpHelper.update: Unknown option #{key}"
            end
          end
             
          @backup_obj.save

          return @backup_obj.compare?(comp_obj)
        end
          
      end
    end
  end
end
