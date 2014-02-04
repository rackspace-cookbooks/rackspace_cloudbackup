plugin_install = template "#{node['ohai']['plugin_path']}/rackspace_cloudbackup.rb" do
  source 'plugins/rackspace_cloudbackup.rb.erb'
  owner  'root'
  group  'root'
  mode   '0644'
  variables(bootstrap_file: '/etc/driveclient/bootstrap.json')
  #  notifies :reload, 'ohai[reload_rackspace_cloudbackup]', :immediately
  action :create
end

ohai "reload" do
  action :reload
end

ruby_block 'print cloudbackup info' do
  block do
    Chef::Log.warn("DEBUG: #{node['rackspace']}")
    #Chef::Log.warn("DEBUG: Registered: #{node['rackspace']['cloudbackup']['is_registered']}")
    #Chef::Log.warn("DEBUG: Agent ID: #{node['rackspace']['cloudbackup']['agent_id']}")
  end
end
