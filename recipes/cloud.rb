# Cookbook Name:: rackspace_cloudbackup
# Recipe:: cloud
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

# Install the agent
include_recipe 'rackspace_cloudbackup::cloud_agent'

# Install deps for the Python scripts
if platform_family?('rhel')
  # python-argparse and PyYAML are in the EPEL repo on RHEL
  yum_repository 'epel' do
    description 'Extra Packages for Enterprise Linux'
    mirrorlist 'http://mirrors.fedoraproject.org/mirrorlist?repo=epel-6&arch=$basearch'
    gpgkey 'http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6'
    action :create
  end

  %w(python-argparse PyYAML).each do |dep|
    package dep do
      action :install
    end
  end

elsif platform_family?('debian')
  %w(python-argparse python-yaml).each do |dep|
    package dep do
      action :install
    end
  end
else
  fail "Unknown platform node['platform']"
end

# Insert our scripts
['run_backup.py'].each do |script|
  cookbook_file "/usr/local/bin/#{script}" do
    source script
    mode 00755
    owner 'root'
    group 'root'
  end
end

# Load in the Opscode::Rackspace::CloudBackup module
class Chef::Recipe
  include Opscode::Rackspace::CloudBackup
end

# Configure our backups
template_data = []
node['rackspace_cloudbackup']['backups'].each do |node_job|
  job = node_job.dup # Obtain a copy that's not in the node attributes so we can tinker in it

  if job['label'].nil?
    # NOTE: This format intentionally matches earlier revisions to avoid creating duplicate backups
    job['label'] = "Backup for #{node['ipaddress']}, backing up #{job['location']}"
  end

  if job['cloud'].nil?
    job['cloud'] = {}
  end

  if job['enabled'].nil?
    job['enabled'] = true
  end

  rackspace_cloudbackup_configure_cloud_backup job['label'] do
    rackspace_username   node['rackspace']['cloud_credentials']['username']
    rackspace_api_key    node['rackspace']['cloud_credentials']['api_key']
    rackspace_api_region node['rackspace']['datacenter']
    inclusions           [job['location']]

    version_retention    job['cloud']['version_retention'] || node['rackspace_cloudbackup']['backups_defaults']['cloud_version_retention']
    notify_recipients    job['cloud']['notify_email']      || node['rackspace_cloudbackup']['backups_defaults']['cloud_notify_email']
    is_active            job['enabled']

    # Backups configured with this module are triggered by cron for consistency with non-RS cloud
    frequency            'Manually'

    # For various tests
    mock                 node['rackspace_cloudbackup']['mock']
    action :create
  end

  # Shared defininition from definitions/cron_wrapper.rb
  cloud_backup_cron_configurator "#{job['label']} cron_configurator" do
    job job
    command "/usr/local/bin/run_backup.py --location '#{job['location']}'"
  end

  # Set up the array the config template will use
  # This is separate from node['rackspace_cloudbackup']['backups'] to use the label logic above
  template_data.push('label'    => job['label'],
                     'location' => job['location'],
                     'comment'  => job['comment'],
                     'enabled'  => job['enabled'])

end

# Write the configuration file for the cron job script
template '/etc/driveclient/run_backup.conf.yaml' do
  source 'run_backup.config.yaml.erb'
  owner 'root'
  group 'root'
  mode '0600'
  action :create
  variables(
            api_username:  node['rackspace']['cloud_credentials']['username'],
            api_key:       node['rackspace']['cloud_credentials']['api_key'],
            api_region:    node['rackspace']['datacenter'],
            mock:          node['rackspace_cloudbackup']['mock'],
            backup_config: template_data
            )
end

# Clean up after earlier revisions
%w(auth.py backups_created create_backup.py .registered verify_registration.py configure_run_backup.py run_backup run_backup.conf.json).each do |target|
  file "/etc/driveclient/#{target}" do
    action :delete
  end
end
