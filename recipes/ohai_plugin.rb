# Cookbook Name:: rackspace_cloudbackup
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

template "#{node['ohai']['plugin_path']}/rackspace_cloudbackup.rb" do
  source 'plugins/rackspace_cloudbackup.rb.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  variables(bootstrap_file: '/etc/driveclient/bootstrap.json')
  notifies :reload, 'ohai[reload]', :immediately
  action :create
end

ohai "reload" do
  action :reload
end

include_recipe 'ohai::default'

ruby_block 'print cloudbackup info' do
  block do
    Chef::Log.info("Rackspace CloudBackup Agent Registered: #{node['rcbu']['is_registered']}")
    Chef::Log.info("Rackspace CloudBackup Agent Agent ID: #{node['rcbu']['agent_id']}")
  end
end
