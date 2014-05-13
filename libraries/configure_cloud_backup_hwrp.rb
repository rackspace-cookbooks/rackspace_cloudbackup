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

require_relative 'RcbuBackupWrapper.rb'

class Chef
  class Resource
    # Implement the rackspace_cloudbackup_register_agent resource

    # TODO: This naming is poor.  rackspace_cloudbackup_backup_configuration or similar would make more sense.
    class RackspaceCloudbackupConfigureCloudBackup < Chef::Resource
      attr_accessor :api_obj
      attr_writer   :api_obj

      def initialize(name, run_context = nil)
        super
        @resource_name = :rackspace_cloudbackup_configure_cloud_backup       # Bind ourselves to the name with an underscore
        @provider = Chef::Provider::RackspaceCloudbackupConfigureCloudBackup # We need to tie to our provider
        @action = :create  # Default Action
        @allowed_actions = [:create, :create_if_missing, :nothing]

        @label = name

        # Set basic defaults
        @is_active = true
        @missed_backup_action_id = 1 # See http://docs.rackspace.com/rcbu/api/v1.0/rcbu-devguide/content/createConfig.html
        @notify_success          = false
        @notify_failure          = true
        @time_zone_id            = 'UTC'
        @mock                    = false
        @rcbu_bootstrap_file     = '/etc/driveclient/bootstrap.json'
      end

      def label(arg = nil)
        # set_or_return is a magic function from Chef that does most of the heavy lifting for attribute access.
        set_or_return(:label, arg, kind_of: String)
      end

      def rackspace_username(arg = nil)
        set_or_return(:rackspace_username, arg, kind_of: String, required: true)
      end

      def rackspace_api_key(arg = nil)
        set_or_return(:rackspace_api_key, arg, kind_of: String, required: true)
      end

      def rackspace_api_region(arg = nil)
        set_or_return(:rackspace_api_region, arg, kind_of: String, required: true)
      end

      def inclusions(arg = nil)
        set_or_return(:inclusions, arg, kind_of: Array, required: true)
      end

      def exclusions(arg = nil)
        set_or_return(:exclusions, arg, kind_of: Array)
      end

      def is_active(arg = nil)
        set_or_return(:is_active, arg, kind_of: [TrueClass, FalseClass])
      end

      def version_retention(arg = nil)
        set_or_return(:version_retention, arg, kind_of: Integer, required: true)
      end

      def frequency(arg = nil)
        set_or_return(:frequency, arg, kind_of: String)
      end

      def start_time_hour(arg = nil)
        set_or_return(:start_time_hour, arg, kind_of: Integer)
      end

      def start_time_minute(arg = nil)
        set_or_return(:start_time_minute, arg, kind_of: Integer)
      end

      def start_time_am_pm(arg = nil)
        set_or_return(:start_time_am_pm, arg, kind_of: Integer)
      end

      def day_of_week_id(arg = nil)
        set_or_return(:day_of_week_id, arg, kind_of: Integer)
      end

      def hour_interval(arg = nil)
        set_or_return(:hour_interval, arg, kind_of: Integer)
      end

      def time_zone_id(arg = nil)
        set_or_return(:time_zone_id, arg, kind_of: String)
      end

      def notify_recipients(arg = nil)
        set_or_return(:notify_recipients, arg, kind_of: String, required: true)
      end

      def notify_success(arg = nil)
        set_or_return(:notify_success, arg, kind_of: [TrueClass, FalseClass])
      end

      def notify_failure(arg = nil)
        set_or_return(:notify_failure, arg, kind_of: [TrueClass, FalseClass])
      end

      def backup_prescript(arg = nil)
        set_or_return(:backup_prescript, arg, kind_of: String)
      end

      def backup_postscript(arg = nil)
        set_or_return(:backup_postscript, arg, kind_of: String)
      end

      def missed_backup_action_id(arg = nil)
        set_or_return(:missed_backup_action_id, arg, kind_of: Integer)
      end

      def mock(arg = nil)
        set_or_return(:mock, arg, kind_of: [TrueClass, FalseClass])
      end

      def rcbu_bootstrap_file(arg = nil)
        set_or_return(:rcbu_bootstrap_file, arg, kind_of: String)
      end
    end
  end
end

class Chef
  class Provider
    # Implement the rackspace_cloudbackup_register_agent provider
    class RackspaceCloudbackupConfigureCloudBackup < Chef::Provider
      def load_current_resource
        @current_resource ||= Chef::Resource::RackspaceCloudbackupConfigureCloudBackup.new(new_resource.name)
        [:label, :rackspace_api_key, :rackspace_username, :rackspace_api_region, :inclusions, :exclusions, :is_active,
         :version_retention, :frequency, :start_time_hour, :start_time_minute, :start_time_am_pm, :day_of_week_id, :hour_interval,
         :time_zone_id, :notify_recipients, :notify_success, :notify_failure, :backup_prescript, :backup_postscript, :missed_backup_action_id,
         :mock, :rcbu_bootstrap_file
        ].each do |arg|
          @current_resource.send(arg, new_resource.send(arg))
        end

        # Load the API object
        @current_resource.api_obj = Opscode::Rackspace::CloudBackup::RcbuBackupWrapper.new(@current_resource.rackspace_username,
                                                                                           @current_resource.rackspace_api_key,
                                                                                           @current_resource.rackspace_api_region,
                                                                                           @current_resource.label,
                                                                                           @current_resource.mock,
                                                                                           @current_resource.rcbu_bootstrap_file
                                                                                           )

        @current_resource
      end

      def action_create
        new_resource.updated_by_last_action(
          @current_resource.api_obj.update(
            inclusions:        @current_resource.inclusions,
            exclusions:        @current_resource.exclusions,
            is_active:         @current_resource.is_active,
            version_retention: @current_resource.version_retention,
            frequency:         @current_resource.frequency,
            start_time_hour:   @current_resource.start_time_hour,
            start_time_minute: @current_resource.start_time_minute,
            start_time_am_pm:  @current_resource.start_time_am_pm,
            day_of_week_id:    @current_resource.day_of_week_id,
            hour_interval:     @current_resource.hour_interval,
            time_zone_id:      @current_resource.time_zone_id,
            notify_recipients: @current_resource.notify_recipients,
            notify_success:    @current_resource.notify_success,
            notify_failure:    @current_resource.notify_failure,
            backup_prescript:  @current_resource.backup_prescript,
            backup_postscript: @current_resource.backup_postscript,
            missed_backup_action_id: @current_resource.missed_backup_action_id
          )
        )
      end

      def action_create_if_missing
        if @current_resource.api_obj.backup_obj.BackupConfigurationId.nil?
          action_create
        else
          new_resource.updated_by_last_action(false)
        end
      end

      def action_nothing
        new_resource.updated_by_last_action(false)
      end
    end
  end
end
