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

# CloudAgentSpecHelpers: Helpers for this test
module CloudAgentSpecHelpers
  def initialize_tests
    # This is required here as ChefSpec interferes with WebMocks, breaking tests
    # rspec does not fully reinitialize the global namespace, so anything declared outside of tests
    # shared between all tests.
    require 'chefspec_helper'
  end
  module_function :initialize_tests
end

describe 'rackspace_cloudbackup::cloud' do
  # This may cause webmock interference here
  # TODO: Determine if this is safe.
  CloudAgentSpecHelpers.initialize_tests

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
            end
          end

          before :each do
            chef_run.converge('rackspace_cloudbackup::cloud')
          end

          it 'Installs the cloud backup repository' do
            case platform.to_s
            when 'redhat', 'centos'
              expect(chef_run).to include_recipe('yum-epel')
            when 'ubuntu', 'debian'
              expect(chef_run).to add_apt_repository('cloud-backup')
            else
              fail "ERROR: Unknown platform #{platform}"
            end
          end

          it 'Installs DriveClient' do
            expect(chef_run).to upgrade_package('driveclient')
          end

          it 'Registers DriveClient' do
            expect(chef_run).to register_agent('Register Fauxhai')
          end

          it 'Enables DriveClient' do
            expect(chef_run).to enable_service('driveclient')
          end

          it 'Starts DriveClient' do
            expect(chef_run).to start_service('driveclient')
          end
        end
      end
    end
  end
end
