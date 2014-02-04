ohai 'reload_rackspace_cloudbackup' do
  plugin 'rackspace_cloudbackup'
  action :nothing
end

template "#{node['ohai']['plugin_path']}/rackspace_cloudbackup.rb" do
  source 'plugins/rackspace_cloudbackup.rb.erb'
  owner  'root'
  group  'root'
  mode   '0755'
  notifies :reload, 'ohai[reload_rackspace_cloudbackup]', :immediately
  variables(bootstrap_file: '/etc/driveclient/bootstrap.json')
end

include_recipe 'ohai::default'
