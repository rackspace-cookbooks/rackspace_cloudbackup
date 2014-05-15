#
# Cookbook Name:: rackspace-cloud-backup
# Attributes:: default
#
# Copyright:: 2013, Rackspace US, inc. <matt.thode@rackspace.com>
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
# General Settings
#

# We use the shared node['rackspace']['cloud_credentials'] for the username and api key
# These credentials are required.
# default['rackspace']['cloud_credentials']['username']
# default['rackspace']['cloud_credentials']['api_key']

# Datacenter to send backups to
# TODO: Properly automate this outside this cookbook, this only works in cloud.
default['rackspace']['datacenter'] = node['rackspace']['region']

#
# Backups configuration
#

# backups is a list of hashes of filesystem locations to backup
# The hash format is: {
#   label: Unique backup label WARNING: SEE README!
#   location: filesystem path to backup (Required)
#   comment:   Some comment (optional)
#   enable:    Enable the backup, Boolean, Optional with default of true
#   cloud: Hash of options specific to Rackspace Cloud Servers.  Format: {
#      notify_email: Email address for notifications on Rackspace Cloud
#      version_retention: Retention value, see API documentation
#   }
#   time: Time override hash for this backup.  (Optional) Format: {
#      day: Day of month to run backup
#      month: Month to run backup
#      hour: Hour to run backup
#      minute: Minute to run backup
#      weekday: Day of week to run backup
#   }
#   cron: Cron override hash for this backup.  (Optional) Format: {
#      user:   User to run the job as
#      mailto: Address to send error messages to
#      path:   Cron path
#      shell:  Cron shell
#      home:   Cron home
#  }
# }
# Many of the above options will pull from the default hash.
# See the default hash description below for defaults and requirement details
default['rackspace_cloudbackup']['backups'] = []

#
# Defaults
#

# cloud_notify_email: Email address to send notifications from Rackspace Cloud Backups to
#   Required on Rackspace Cloud.  Notifications will come from Rackspace servers, must be a valid address.
# Note: This is different from the Cron email address in case there are any issues with mail from the system MTA
default['rackspace_cloudbackup']['backups_defaults']['cloud_notify_email'] = nil

# cloud_version_retention: Rackspace Cloud Backup retention value
# See API documentation, only a small number of values are legal
default['rackspace_cloudbackup']['backups_defaults']['cloud_version_retention'] = 30

# non_cloud_container: Default CloudFiles container for non-cloud containers
default['rackspace_cloudbackup']['backups_defaults']['non_cloud_container'] = nil

# time: backup timing settings.  These settings are Cron format.
default['rackspace_cloudbackup']['backups_defaults']['time']['day']     = '*'
default['rackspace_cloudbackup']['backups_defaults']['time']['month']   = '*'
default['rackspace_cloudbackup']['backups_defaults']['time']['hour']    = '3'
default['rackspace_cloudbackup']['backups_defaults']['time']['minute']  = '14'
default['rackspace_cloudbackup']['backups_defaults']['time']['weekday'] = '*'

# Cron settings: Default settings for the cron jobs
default['rackspace_cloudbackup']['backups_defaults']['cron']['user']   = nil
default['rackspace_cloudbackup']['backups_defaults']['cron']['mailto'] = nil
default['rackspace_cloudbackup']['backups_defaults']['cron']['path']   = nil
default['rackspace_cloudbackup']['backups_defaults']['cron']['shell']  = nil
default['rackspace_cloudbackup']['backups_defaults']['cron']['home']   = nil
