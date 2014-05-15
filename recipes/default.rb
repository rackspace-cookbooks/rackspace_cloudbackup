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
    include_recipe 'rackspace_cloudbackup::cloud'
  else
    fail "ERROR: backups currently unsupported on #{node['cloud']['provider']} cloud servers"
  end
else
  fail "ERROR: backups currently unsupported on non-cloud servers"
end
