#
# Cookbook Name:: rackspace-cloud-backup
# Recipe:: cloud
#
# Copyright 2013, Rackspace US, Inc.
#
# Apache 2.0
#

#
# Verify mandatory options are set
#
opt_error = false
['rackspace_username', 'rackspace_apikey', 'cloud_notify_email', 'backup_locations'].each do |option|
  if node['rackspace_cloud_backup'][option].nil?
    # Logging, and not raising, here so that all missing args will be logged in one run
    Chef::Log.warn "ERROR: rackspace-cloud-backup::cloud: Mandatory option #{option} unset"
    opt_error = true
  end
end
if opt_error
  raise RuntimeError, "Mandatory option configuration unset, see previous logs for details"
end
# End option verification

case node[:platform]
  when "redhat", "centos"
    yum_repository "cloud-backup" do
      description "Rackspace cloud backup agent repo"
      url "http://agentrepo.drivesrvr.com/redhat/"

      # This will be needed with opscode-yum ~> 3.0, but not present on opscode-yum <3.0.0
      # gpgcheck false
  end
  when "ubuntu","debian"
    apt_repository "cloud-backup" do
      uri "http://agentrepo.drivesrvr.com/debian/"
      arch "amd64"
      distribution "serveragent"
      components ["main"]
      key "http://agentrepo.drivesrvr.com/debian/agentrepo.key"
      action :add
  end
end

package "driveclient" do
  action :upgrade
end

execute "registration" do
  command "driveclient -c -u #{node['rackspace_cloud_backup']['rackspace_username']} -k #{node['rackspace_cloud_backup']['rackspace_apikey']} && touch /etc/driveclient/.registered"
  creates "/etc/driveclient/.registered"
  action :run

  # Immediately restart as a [re]start is requred to write a key into bootstrap.json needed by create-backup.py
  notifies :restart, "service[driveclient]", :immediately
end

service "driveclient" do
  action :enable
end

#
# Install deps for the backup scripts
#
package "python-argparse" do
  action :install
end


#insert the backup creation script
cookbook_file "/etc/driveclient/auth.py" do
  source "auth.py"
  mode 00755
  owner "root"
  group "root"
end
cookbook_file "/etc/driveclient/create-backup.py" do
  source "create_backup.py"
  mode 00755
  owner "root"
  group "root"
end

#create the backup
for location in node['rackspace_cloud_backup']['backup_locations'] do
  execute "create backup" do
    command "echo '#!/usr/bin/env bash' >> /etc/driveclient/run_backup; /etc/driveclient/create-backup.py -u #{node['rackspace_cloud_backup']['rackspace_username']} -a #{node['rackspace_cloud_backup']['rackspace_apikey']} -d #{location} -e #{node['rackspace_cloud_backup']['cloud_notify_email']} -i #{node['ipaddress']} >> /etc/driveclient/run_backup"
    creates "/etc/driveclient/backups_created"
    action :run
  end
end
file "/etc/driveclient/backups_created" do
  owner "root"
  group "root"
  mode "0444"
  action :touch
end
cron "cloud-backup-trigger" do
  if node['rackspace_cloud_backup']['backup_cron_day']
    day node['rackspace_cloud_backup']['backup_cron_day']
  end
  if node['rackspace_cloud_backup']['backup_cron_hour']
    hour node['rackspace_cloud_backup']['backup_cron_hour']
  end
  if node['rackspace_cloud_backup']['backup_cron_minute']
    minute node['rackspace_cloud_backup']['backup_cron_minute']
  end
  if node['rackspace_cloud_backup']['backup_cron_month']
    month node['rackspace_cloud_backup']['backup_cron_month']
  end
  if node['rackspace_cloud_backup']['backup_cron_weekday']
    weekday node['rackspace_cloud_backup']['backup_cron_weekday']
  end
  if node['rackspace_cloud_backup']['backup_cron_user']
    user node['rackspace_cloud_backup']['backup_cron_user']
  end
  if node['rackspace_cloud_backup']['backup_cron_mailto']
    mailto node['rackspace_cloud_backup']['backup_cron_mailto']
  end
  if node['rackspace_cloud_backup']['backup_cron_path']
    path node['rackspace_cloud_backup']['backup_cron_path']
  end
  if node['rackspace_cloud_backup']['backup_cron_shell']
    shell node['rackspace_cloud_backup']['backup_cron_shell']
  end
  if node['rackspace_cloud_backup']['backup_cron_home']
    home node['rackspace_cloud_backup']['backup_cron_home']
  end
  command "/etc/driveclient/run_backup"
  action :create
end
file "/etc/driveclient/run_backup" do
  owner "root"
  group "root"
  mode "0750"
  action :create
end

