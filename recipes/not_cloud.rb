#
# Cookbook Name:: rackspace-cloud-backup
# Recipe:: default
#
# Copyright 2013, Rackspace US, Inc.
#
# Apache 2.0
#
# set up repos

case node[:platform]
when 'redhat', 'centos'
  yum_repository 'rackops-repo' do
    description 'Rackspace rackops repo'
    url 'http://repo.rackops.org/rpm/'
    gpgkey 'http://repo.rackops.org/rackops-signing-key.asc'
  end
when 'ubuntu', 'debian'
  case node['lsb'][:codename]
  when 'precise'
    apt_repository 'rackops-repo' do
      uri 'http://repo.rackops.org/apt/ubuntu'
      distribution 'precise'
      components ['main']
      key 'http://repo.rackops.org/rackops-signing-key.asc'
      action :add
    end
  when 'wheezy'
    apt_repository 'rackops-repo' do
      uri 'http://repo.rackops.org/apt/debian'
      distribution 'wheezy'
      components ['main']
      key 'http://repo.rackops.org/rackops-signing-key.asc'
      action :add
    end
  end
end

# install turbolift
package 'python-turbolift' do
  action :upgrade
end

# Install the helper wrapper
['turbolift_backup.sh'].each do |script|
  cookbook_file "/usr/local/bin/#{script}" do
    source script
    mode 00755
    owner 'root'
    group 'root'
  end
end

# Ensure mandatory options are set
if node['rackspace']['cloud_credentials']['username'].nil? || node['rackspace']['cloud_credentials']['api_key'].nil?
  fail 'ERROR: Cloud credentials unset'
end

fail 'ERROR: datacenter not set' if node['rackspace']['datacenter'].nil?

node['rackspace_cloudbackup']['backups'].each do |node_job|
  job = node_job.dup # Obtain a copy that's not in the node attributes so we can tinker in it

  if job['label'].nil?
    # NOTE: This format intentionally matches earlier revisions to avoid creating duplicate backups
    job['label'] = "Backup for #{node['ipaddress']}, backing up #{job['location']}"
  end

  if job['non_cloud'].nil?
    job['non_cloud'] = {}
  end

  if job['enabled'].nil?
    job['enabled'] = true
  end

  container = job['non_cloud']['container'].nil? ? node['rackspace_cloudbackup']['backups_defaults']['non_cloud_container'] : job['non_cloud']['container']
  fail "ERROR: Target backup container not set for location \"#{job['location']}\"" if container.nil?

  # Build the command
  # Broken up to keep lines short and to enable flag toggles
  command_str = '/usr/local/bin/turbolift_backup.sh -s'
  command_str += " -u #{node['rackspace']['cloud_credentials']['username']}"
  command_str += " -k #{node['rackspace']['cloud_credentials']['api_key']}"
  command_str += " -d #{node['rackspace']['datacenter']}"
  command_str += " -c #{container}"
  command_str += " -l \"#{job['location']}\""

  unless job['enabled']
    # Set the disabled bit
    # This is the primary value of the wrapper script, the job will still exist but turbolift won't run.
    command_str += ' -D'
  end

  # Shared defininition from definitions/cron_wrapper.rb
  cloud_backup_cron_configurator "#{job['label']} cron_configurator" do
    job job
    command command_str
  end
end
