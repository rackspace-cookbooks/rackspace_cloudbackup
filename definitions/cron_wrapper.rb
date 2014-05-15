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
define(:cloud_backup_cron_configurator, job: nil, command: nil) do
  # Avoid nil exceptions going forward
  if params[:job]['time'].nil?
    params[:job]['time'] = {}
  end
  if params[:job]['cron'].nil?
    params[:job]['cron'] = {}
  end

  # By default these are appended to root's crontab
  cron "'#{params[:job]['label']}' cronjob" do
    month   params[:job]['time']['month']   || node['rackspace_cloudbackup']['backups_defaults']['time']['month']
    day     params[:job]['time']['day']     || node['rackspace_cloudbackup']['backups_defaults']['time']['day']
    hour    params[:job]['time']['hour']    || node['rackspace_cloudbackup']['backups_defaults']['time']['hour']
    minute  params[:job]['time']['minute']  || node['rackspace_cloudbackup']['backups_defaults']['time']['minute']
    weekday params[:job]['time']['weekday'] || node['rackspace_cloudbackup']['backups_defaults']['time']['weekday']

    user    params[:job]['cron']['user']   || node['rackspace_cloudbackup']['backups_defaults']['cron']['user']
    mailto  params[:job]['cron']['mailto'] || node['rackspace_cloudbackup']['backups_defaults']['cron']['mailto']
    path    params[:job]['cron']['path']   || node['rackspace_cloudbackup']['backups_defaults']['cron']['path']
    shell   params[:job]['cron']['shell']  || node['rackspace_cloudbackup']['backups_defaults']['cron']['shell']
    home    params[:job]['cron']['home']   || node['rackspace_cloudbackup']['backups_defaults']['cron']['home']

    command  params[:command]
    action :create
  end
end
