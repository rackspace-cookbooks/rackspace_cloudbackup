action :register do
  unless node.key?('rcbu')
    fail "rcbu node attributes not defined: Ensure the rackspace_cloudbackup ohai plugin is installed"
  end
  
  case node['rcbu']['is_registered']
  when false
    # Using Mixlib::ShellOut because execute was being run after the RPs it notified.  (?!?!?)
    cmdStr = "driveclient -c -k #{new_resource.rackspace_api_key} -u #{new_resource.rackspace_username}"
    cmd = Mixlib::ShellOut.new(cmdStr)
    cmd.run_command
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
