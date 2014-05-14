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

# Define the unique helper module for this test suite.
module NotCloudSpecHelpers
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
            { 'label' => 'test /dev/null backup', 'location' => '/dev/null' }
           ]
  end
  module_function :test_backup_data
end

describe 'rackspace_cloudbackup::cloud' do
  # TODO: Determine if this causes conflicts at this level.
  NotCloudSpecHelpers.initialize_tests

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
              node.set['rackspace']['datacenter']                    = 'DFW'
              node.set['rackspace_cloudbackup']['backups_defaults']['non_cloud_container'] = 'testContainer'
            end
          end

          before :each do
            chef_run.node.set['rackspace_cloudbackup']['backups'] = NotCloudSpecHelpers.test_backup_data
            chef_run.converge('rackspace_cloudbackup::not_cloud')
          end

          # TODO: Test failure on missing settings

          it 'Installs the rackops-repo repository' do
            case platform.to_s
            when 'redhat', 'centos'
              expect(chef_run).to create_yum_repository('rackops-repo')
            when 'ubuntu', 'debian'
              expect(chef_run).to add_apt_repository('rackops-repo')
            else
              fail "ERROR: Unknown platform #{platform}"
            end
          end

          it 'installs python-argparse' do
            expect(chef_run).to upgrade_package 'python-turbolift'
          end

          it 'installs turbolift_backup.sh' do
            expect(chef_run).to render_file('/usr/local/bin/turbolift_backup.sh')
          end

          NotCloudSpecHelpers.test_backup_data.each do |job|
            describe "test backup of '#{job['location']}'" do
              # Test the behavior, not the implementation.  Don't worry that it's a definition
              # This is shared with cloud, and can be deduped.
              it 'configures the cron job' do
                # TODO: Also spartan
                expect(chef_run).to create_cron("'#{job['label']}' cronjob")
              end
            end
          end
        end
      end
    end
  end
end
