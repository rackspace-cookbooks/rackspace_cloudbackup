# non_cloud_spec.rb: serverspec file for testing the non_cloud recipe

require 'spec_helper'

describe 'Cloud server' do
  # As we mock registration driveclient won't have a config and won't be running, but it should be installed and enabled
  describe package('driveclient') do
    it { should be_installed }
  end

  it 'should have driveclient enabled' do
    expect(service 'driveclient').to be_enabled
  end

  describe file('/usr/local/bin/run_backup.py') do
    it { should be_file }
    it { should be_executable }
    it { should be_owned_by 'root' }
    it { should be_readable.by('others') }
  end

  describe command('/usr/local/bin/run_backup.py --help') do
    # If there are dependency errors this won't return 0
     its(:exit_status) { should eq 0 }
  end

  describe file('/etc/driveclient/run_backup.conf.yaml') do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_mode 600 } # As it contains the API key

    # TODO: Test the YAML file properly
    it { should contain 'apikey: secret' }
    it { should contain 'apiuser: nobody' }
    it { should contain 'region: DFW' }
    it { should contain '/etc' }
    it { should contain '/home' }
  end

  describe file(SpecHelpers.crontab_path) do
    it { should be_file }
    it { should be_owned_by 'root' }

    # Check the jorbs
    # These settings come through from the .kitchen.yml file
    it { should contain "/usr/local/bin/run_backup.py --location '/etc'" }
    it { should contain "/usr/local/bin/run_backup.py --location '/home'" }
  end
end
