action :register do
  unless node.key? rcbu
    fail "rcbu node attributes not defined: Ensure the rackspace_cloudbackup ohai plugin is installed"
  end
  
  case node['rcbu']['is_registered']
  when false
    execute "registration" do
      command "driveclient -c -u #{new_resource.rackspace_api_key} -k #{new_resource.rackspace_username}"
      creates "/etc/driveclient/.registered"
      action :run
      notifies :restart, "service[driveclient]"
    end
    new_resource.updated_by_last_action(true)
  when true
    new_resource.updated_by_last_action(false)
  else
    fail "Rackspace CloudBackup Agent registration in unknown state: #{node['rcbu']['is_registered']}"
  end
end

def load_current_resource
  # Nothing to load.  Status comes from the node attributes.
end
