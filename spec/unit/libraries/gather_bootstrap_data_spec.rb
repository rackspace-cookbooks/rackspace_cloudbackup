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

require 'tempfile'
require 'json'

module GatherBootstrapDataTestHelpers
  class DummyBootstrapFile
    def initialize(content)
      @file = Tempfile.new('rackspaceCloudbackup_gatherBootstrapData_testData')
      @file.sync = true

      @file.write(content)
      @file.flush # Belt & suspenders
    end

    def path
      return @file.path()
    end

    def close
      # Following best practice per
      # http://www.ruby-doc.org/stdlib-1.9.3/libdoc/tempfile/rdoc/Tempfile.html
      @file.close
      @file.unlink   # deletes the temp file
    end
  end
end

describe 'gather_bootstrap_data' do
  before :each do
    # ChefSpec conflicts with rspec which breaks WebMock tests.  Require ChefSpec in test scope.
    require 'chefspec_helper'
    require_relative '../../../libraries/gather_bootstrap_data.rb'
  end

  it 'returns nil when the target file does not exist' do
    Opscode::Rackspace::CloudBackup.gather_bootstrap_data('/dev/null/this/should/be/sufficiently/bogus').should eql nil
  end

  it 'returns nil when the content is malformed' do
    test_file = GatherBootstrapDataTestHelpers::DummyBootstrapFile.new('wqerklkshksdagksaldgvbwae;o')
    Opscode::Rackspace::CloudBackup.gather_bootstrap_data(test_file.path).should eql nil
    test_file.close
  end

  it 'returns properly formatted content' do
    test_content = {'foo' => 'bar', 'bar' => 'baz', 'baz' => 'foobar'}
    test_file = GatherBootstrapDataTestHelpers::DummyBootstrapFile.new(JSON.dump(test_content))
    Opscode::Rackspace::CloudBackup.gather_bootstrap_data(test_file.path).should eql test_content
    test_file.close
  end
end
