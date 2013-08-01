#
# Cookbook Name:: rackspace-cloud-backup
# Recipe:: default
#
# Copyright 2013, Rackspace US, Inc.
#
# Apache 2.0
#
if node['cloud']['provider'] == 'rackspace'

  case node[:platform]
    when "redhat", "centos"
      yum_repository "cloud-backup" do
        description "Rackspace cloud backup agent repo"
        url "http://agentrepo.drivesrvr.com/redhat/"
    end
    when "ubuntu","debian"
      apt_repository "cloud-backup" do
        uri "http://agentrepo.drivesrvr.com/debian/"
        distribution "serveragent"
        components ["main"]
        key "http://agentrepo.drivesrvr.com/debian/agentrepo.key"
        action :add
    end
  end

  package "driveclient" do
    action :upgrade
  end

  unless node['rackspace_cloud_backup']['rackspace_username'].nil?
    unless node['rackspace_cloud_backup']['rackspace_apikey'].nil?
      execute "registration" do
        command "driveclient -c -u #{node['rackspace_cloud_backup']['rackspace_username']} -k #{node['rackspace_cloud_backup']['rackspace_apikey']} && touch /etc/driveclient/.registered"
        creates "/etc/driveclient/.registered"
        action :run
        notifies :restart, "service[driveclient]"
      end
    end
  end

  service "driveclient" do
    action :enable
  end


else
  

  #set up repos
  case node[:platform]
    when "redhat", "centos"
      yum_repository "rackops-repo" do
        description "Rackspace rackops repo"
        url "http://repo.rackops.org/rpm/"
    end
    when "ubuntu","debian"
      apt_repository "cloud-backup" do
        uri "http://repo.rackops.org/deb/"
	distribution ""
        components ["./"]
        action :add
    end
  end

  #install turbolift
  case node[:platform]
    when "redhat", "centos"
      package "python-turbolift" do
        action :upgrade
    end
    when "ubuntu","debian"
      package "python-turbolift" do
        options "--allow-unauthenticated"
        action :upgrade
    end
  end

  #set up cronjob
  if node['rackspace_cloud_backup']['backup_locations'] && node['rackspace_cloud_backup']['backup_container'] && node['rackspace_cloud_backup']['rackspace_endpoint'] && node['rackspace_cloud_backup']['rackspace_apikey'] && node['rackspace_cloud_backup']['rackspace_username']
    cron "turbolift" do
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
      command "turbolift --os-rax-auth #{node['rackspace_cloud_backup']['rackspace_endpoint']} -u #{node['rackspace_cloud_backup']['rackspace_username']} -a #{node['rackspace_cloud_backup']['rackspace_apikey']} archive -s #{node['rackspace_cloud_backup']['backup_locations']} -c #{node['rackspace_cloud_backup']['backup_container']}"
      action :create
    end
  end

end

