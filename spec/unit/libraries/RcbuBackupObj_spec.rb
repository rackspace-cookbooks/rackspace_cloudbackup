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

require 'spec_helper'

require_relative '../../../libraries/RcbuBackupObj.rb'
require_relative '../../../libraries/MockRcbuApiWrapper.rb'

module RcbuBackupObjTestHelpers
#  def test_data
#    return {
#    }
#  end
#  module_function :test_data

  def test_api_wrapper
    return Opscode::Rackspace::CloudBackup::MockRcbuApiWrapper.new('Test API Username',
                                                                   'Test API Key',
                                                                   'NOWHERE',
                                                                   765432,
                                                                   'http://localhost/')
  end
  module_function :test_api_wrapper
                                                                   
end

describe 'RcbuBackupObj' do
  describe 'initialize' do
    before :each do
#      @test_data        = RcbuBackupObjTestHelpers.test_data
      @test_label       = 'Test Label'
      @test_api_wrapper = RcbuBackupObjTestHelpers.test_api_wrapper
    end

    it 'Sets the label class instance variable' do
      @test_obj = Opscode::Rackspace::CloudBackup::RcbuBackupObj.new(@test_label, @test_api_wrapper)
      @test_obj.label.should eql @test_label
    end

    it 'Sets the api_wrapper class instance variable' do
      @test_obj = Opscode::Rackspace::CloudBackup::RcbuBackupObj.new(@test_label, @test_api_wrapper)
      @test_obj.api_wrapper.should eql @test_api_wrapper
    end
  end
end
    
    
