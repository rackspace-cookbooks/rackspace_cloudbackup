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

  unless node['rackspace_cloud_backup']['username'].nil?
    unless node['rackspace_cloud_backup']['apikey'].nil?
      execute "registration" do
        command "driveclient -c -u #{node['rackspace_cloud_backup']['username']} -k #{node['rackspace_cloud_backup']['apikey']} && touch /etc/driveclient/.registered"
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

end
