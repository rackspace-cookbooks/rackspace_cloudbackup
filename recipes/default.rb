#
# Cookbook Name:: rackspace-cloud-backup
# Recipe:: default
#
# Copyright 2013, Rackspace US, Inc.
#
# Apache 2.0
#
if defined?(node['cloud']['provider'])
  if node['cloud']['provider'] == 'rackspace'
    include_recipe "rackspace-cloud-backup::cloud"
  end
else
  include_recipe "rackspace-cloud-backup::not_cloud"
end
