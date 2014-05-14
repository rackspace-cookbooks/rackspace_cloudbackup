# non_cloud_spec.rb: serverspec file for testing the non_cloud recipe

require 'spec_helper'

describe 'Non-cloud server' do
  describe command('/usr/bin/turbolift --help') do
    # If there are dependency errors or other turbolift errors this won't return 0
    it { should return_exit_status 0 }
  end

  describe file('/usr/local/bin/turbolift_backup.sh') do
    it { should be_file }
    it { should be_executable }
    it { should be_owned_by 'root' }
    it { should be_readable.by('others') }
  end

  describe file('/var/spool/cron/crontabs/root') do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_mode 600 } # As it contins the API key
    
    # Check the jorbs
    # These settings come through from the .kitchen.yml file
    it { should contain '/usr/local/bin/turbolift_backup.sh -s -u nobody -k secret -d DFW -c testContainer -l "/etc" -D' }
    it { should contain '/usr/local/bin/turbolift_backup.sh -s -u nobody -k secret -d DFW -c testContainer -l "/home" -D' }
  end
end
  
