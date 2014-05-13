#
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

require_relative '../../supported_platforms.rb'

module CloudSpecHelpers
  def initialize_tests
    # This is required here as ChefSpec interferes with WebMocks, breaking tests
    # rspec does not fully reinitialize the global namespace, so anything declared outside of tests
    # shared between all tests.
    require 'chefspec_helper'
  end
  module_function :initialize_tests

  def test_backup_data
    return [
            { 'label' => 'test /tmp backup',      'location' => '/tmp/' },
            { 'label' => 'test /dev/null backup', 'location' => '/dev/null' },
           ]
  end
  module_function :test_backup_data
end


describe 'rackspace_cloudbackup::cloud' do
  # TODO: Determine if this causes conflicts at this level.
  CloudSpecHelpers.initialize_tests

  rackspace_cloudbackup_test_platforms.each do |platform, versions|
    describe "on #{platform}" do
      versions.each do |version|
        describe version do
          let(:chef_run) do
            ChefSpec::Runner.new(platform: platform.to_s,
                                 version: version.to_s,
                                 step_into: ['rackspace_cloudmonitoring_agent_token']
                                 ) do |node|
              node.set['rackspace_cloudbackup']['mock'] = true
              node.set['rackspace']['cloud_credentials']['username'] = 'IfThisHitsTheApiSomethingIsBusted'
              node.set['rackspace']['cloud_credentials']['api_key']  = 'SuchFakePassword.VeryMock.Wow.'
              node.set['rackspace_cloudbackup']['backups_defaults']['cloud_notify_email'] = 'root@localhost'
            end
          end
          
          before :each do
            chef_run.node.set['rackspace_cloudbackup']['backups'] = CloudSpecHelpers.test_backup_data
            chef_run.converge('rackspace_cloudbackup::cloud')
          end
        
          it 'includes the cloud_agent recipe' do
            expect(chef_run).to include_recipe 'rackspace_cloudbackup::cloud_agent'
          end

          it 'installs python-argparse' do
            expect(chef_run).to install_package 'python-argparse'
          end
          
          it 'installs run_backup.py' do
            expect(chef_run).to render_file('/usr/local/bin/run_backup.py')
          end
          
          CloudSpecHelpers.test_backup_data.each do |job|
            describe "test backup of '#{job['location']}'" do
              it 'creates a backup configuration' do
                # TODO: The coverage of this hwrp is currently ... spartan.  Many options not tested.
                expect(chef_run).to create_cloudbackup_configure_cloud_backup(job['label']).with(inclusions: [job['location']])
              end

              # Test the behavior, not the implementation.  Don't worry that it's a definition
              it 'configures the cron job' do
                # TODO: Also spartan
                expect(chef_run).to create_cron("'#{job['label']}' cronjob")
              end
            end
          end

          it 'Creates the run_backup.conf.yaml file' do
            expect(chef_run).to render_file('/etc/driveclient/run_backup.conf.yaml')
          end
 
        end
      end
    end
  end
end

          
           
            
