# Cookbook Name:: rackspace_cloudbackup
# Recipe:: cron_wrapper
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

#
# Define a common wrapper around cron we can share between cloud and non-cloud
#
define :cloud_backup_cron_configurator, :job, :command do
  # Avoid nil exceptions going forward
  if job['time'].nil?
    job['time'] = {}
  end
  if job['cron'].nil?
    job['cron'] = {}
  end

  # By default these are appended to root's crontab
  cron "#{job['label']} cronjob" do
    month   job['time']['month']   || node['rackspace_cloudbackup']['backups_defaults']['time']['month']
    day     job['time']['day']     || node['rackspace_cloudbackup']['backups_defaults']['time']['day']
    hour    job['time']['hour']    || node['rackspace_cloudbackup']['backups_defaults']['time']['hour']
    minute  job['time']['minute']  || node['rackspace_cloudbackup']['backups_defaults']['time']['minute']
    weekday job['time']['weekday'] || node['rackspace_cloudbackup']['backups_defaults']['time']['weekday']

    user    job['cron']['user']   || node['rackspace_cloudbackup']['backups_defaults']['cron']['user']
    mailto  job['cron']['mailto'] || node['rackspace_cloudbackup']['backups_defaults']['cron']['mailto']
    path    job['cron']['path']   || node['rackspace_cloudbackup']['backups_defaults']['cron']['path']
    shell   job['cron']['shell']  || node['rackspace_cloudbackup']['backups_defaults']['cron']['shell']
    home    job['cron']['home']   || node['rackspace_cloudbackup']['backups_defaults']['cron']['home']

    command "/etc/driveclient/run_backup"
    action :create
  end
end
