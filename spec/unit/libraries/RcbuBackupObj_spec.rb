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

require 'rspec_helper'

require_relative '../../../libraries/RcbuBackupObj.rb'
require_relative '../../../libraries/MockRcbuApiWrapper.rb'

module RcbuBackupObjTestHelpers
  def test_api_wrapper
    return Opscode::Rackspace::CloudBackup::MockRcbuApiWrapper.new('Test API Username',
                                                                   'Test API Key',
                                                                   'NOWHERE',
                                                                   765432,
                                                                   'http://localhost/')
  end
  module_function :test_api_wrapper

  # Helper class that adds an unlock method which adds setters for ALL attributes
  # Required for compare? tests
  # (Otherwise we have a chicken/egg problem testing compare? and load)
  class UnlockedRcbuBackupObj < Opscode::Rackspace::CloudBackup::RcbuBackupObj
    # THIS MUST NOT OVERRIDE ANY METHODS!  Doing so will invalidate tests!
    def unlock_setters
      @all_attributes.each do |arg|
        self.class.send(:define_method, "#{arg}=", proc { |x| instance_variable_set("@#{arg}", x) })
      end
    end
  end

  # This variable is extremely useful in attribute testing.  This method allows us to access it outside of test scope.
  def get_all_attributes
    return Opscode::Rackspace::CloudBackup::RcbuBackupObj.new(nil, test_api_wrapper).all_attributes
  end
  module_function :get_all_attributes

  def get_settable_attributes
    return Opscode::Rackspace::CloudBackup::RcbuBackupObj.new(nil, test_api_wrapper).settable_attributes
  end
  module_function :get_settable_attributes
end

describe 'RcbuBackupObj' do
  describe 'initialize' do
    before :each do
      @test_label       = 'Test Label'
      @test_api_wrapper = RcbuBackupObjTestHelpers.test_api_wrapper
      @test_obj = Opscode::Rackspace::CloudBackup::RcbuBackupObj.new(@test_label, @test_api_wrapper)
    end

    it 'Sets the label class instance variable' do
      @test_obj.label.should eql @test_label
    end

    it 'Sets the api_wrapper class instance variable' do
      @test_obj.api_wrapper.should eql @test_api_wrapper
    end

    # These don't have to be exhaustive, but they should contain all the attributes manipulated by the HWRP
    %w(Inclusions Exclusions BackupConfigurationId MachineAgentId MachineName Datacenter Flavor IsEncrypted
       EncryptionKey BackupConfigurationName IsActive IsDeleted VersionRetention BackupConfigurationScheduleId
       MissedBackupActionId Frequency StartTimeHour StartTimeMinute StartTimeAmPm DayOfWeekId HourInterval
       TimeZoneId NextScheduledRunTime LastRunTime LastRunBackupReportId NotifyRecipients NotifySuccess
       NotifyFailure BackupPrescript BackupPostscript).each do |attr|
      it "contains #{attr} in the all_attributes class instance variable" do
        @test_obj.all_attributes.include?(attr).should eql true
      end
    end

    %w(Inclusions Exclusions MachineAgentId IsActive VersionRetention
       Frequency StartTimeHour StartTimeMinute StartTimeAmPm DayOfWeekId HourInterval TimeZoneId
       NotifyRecipients NotifySuccess NotifyFailure BackupPrescript BackupPostscript MissedBackupActionId).each do |attr|
      it "contains #{attr} in the settable_attributes class instance variable" do
        @test_obj.settable_attributes.include?(attr).should eql true
      end
    end

    setters = RcbuBackupObjTestHelpers.get_settable_attributes
    RcbuBackupObjTestHelpers.get_all_attributes.each do |attr|
      it "has a getter for #{attr}" do
        # *almost* all should return nil, but not all.  Banking on exceptions.
        @test_obj.send(attr)
      end
    end

    test_variable = "Setter(#{attr}) Test Variable"
    if setters.include?(attr)
      it "has a setter for #{attr}" do
        @test_obj.send("#{attr}=", test_variable)
        @test_obj.send(attr).should eql test_variable
      end
    else
      it "does not have a setter for #{attr}" do
        expect { @test_obj.send("#{attr}=", test_variable) }.to raise_exception
      end
    end

    it 'sets BackupConfigurationName to the label argument' do
      @test_obj.BackupConfigurationName.should eql @test_label
    end

    describe 'with no loaded config' do
      before :each do
        @test_label       = 'Test Label'
        @test_api_wrapper = RcbuBackupObjTestHelpers.test_api_wrapper
        @test_obj = Opscode::Rackspace::CloudBackup::RcbuBackupObj.new(@test_label, @test_api_wrapper)
        fail 'mock data present' if @test_api_wrapper.mock_configurations != []
      end

      it 'sets MachineAgentId to api_wrapper.agent_id' do
        @test_obj.MachineAgentId.should eql @test_api_wrapper.agent_id
      end

      it 'sets Inclusions to an empty array' do
        @test_obj.Inclusions.should eql []
      end

      it 'sets Exclusions to an empty array' do
        @test_obj.Exclusions.should eql []
      end
    end

    describe 'with a loaded config' do
      before :each do
        @test_label       = 'Test Label'
        @test_api_wrapper = RcbuBackupObjTestHelpers.test_api_wrapper

        # Preload the stateful mocks with a dataset containing keys used in the constructor
        # A more exhaustive test will be done against load itself.
        @test_api_wrapper.create_config(  'BackupConfigurationName' => @test_label,
                                          'MachineAgentId'          => 'TestMachineID',
                                          'Inclusions'              => 'TestInclusions', # Technically invalid, but will suffice
                                          'Exclusions'              => 'TestExclusions', # Technically invalid, but will suffice
                                          )

        @test_obj = Opscode::Rackspace::CloudBackup::RcbuBackupObj.new(@test_label, @test_api_wrapper)
      end

      it 'does not override MachineAgentId' do
        @test_obj.MachineAgentId.should eql 'TestMachineID'
      end

      it 'does not override Inclusions' do
        @test_obj.Inclusions.should eql 'TestInclusions'
      end

      it 'does not override Exclusions' do
        @test_obj.Exclusions.should eql 'TestExclusions'
      end
    end
  end

  describe 'compare?' do
    before :each do
      @test_label       = 'Test Label'
      @test_api_wrapper = RcbuBackupObjTestHelpers.test_api_wrapper

      # Use the unlocked wrapper and unlock the setters
      @test_obj = RcbuBackupObjTestHelpers::UnlockedRcbuBackupObj.new(@test_label, @test_api_wrapper)
      @test_obj.unlock_setters

      # Create a hash of test values
      @test_values = {}
      @test_differing_values = {}
      # Create a default string for all values
      @test_obj.all_attributes.each do |attr|
        @test_values[attr] = "Test #{attr} Value"
        @test_differing_values[attr] = "Test Duiffering #{attr} Value"
      end
      # Inclusions and Exclusions must be arrays of hashes
      # They are handled differently by the .dup override to make a deep copy
      @test_values['Inclusions'] = [{ val: 'Test Includes Value 1' }, { val: 'Test Includes Value 2' }]
      @test_differing_values['Inclusions'] = [{ val: 'Test Differing Includes Value 1' }, { val: 'Test Includes Value 2' }]
      @test_values['Exclusions'] = [{ val: 'Test Excludes Value 1' }, { val: 'Test Excludes Value 2' }]
      @test_differing_values['Inclusions'] = [{ val: 'Test Differing Includes Value 1' }, { val: 'Test Includes Value 2' }]
    end

    it 'returns true when all attributes are the same' do
      @test_obj.all_attributes.each do |attr|
        @test_obj.send("#{attr}=", @test_values[attr])
        @test_obj.send(attr).should eql @test_values[attr]
      end

      comp_obj = @test_obj.dup
      @test_obj.compare?(comp_obj).should eql true
    end

    RcbuBackupObjTestHelpers.get_all_attributes.each do |attr|
      it "returns false when #{attr} differ" do
        @test_obj.all_attributes.each do |init_attr|
          @test_obj.send("#{init_attr}=", @test_values[init_attr])
          @test_obj.send(init_attr).should eql @test_values[init_attr]
        end

        comp_obj = @test_obj.dup
        comp_obj.send("#{attr}=", @test_differing_values[attr])
        @test_obj.send(attr).should_not eql comp_obj.send(attr)
        @test_obj.compare?(comp_obj).should eql false
      end
    end
  end

  # NOTE: These tests should run AFTER compare? as we use compare? for no change tests
  describe 'load' do
    before :each do
      @test_label       = 'Test Label'
      @test_api_wrapper = RcbuBackupObjTestHelpers.test_api_wrapper
      @test_obj = Opscode::Rackspace::CloudBackup::RcbuBackupObj.new(@test_label, @test_api_wrapper)
    end

    it 'doesn\'t modify the class when no configuration is loaded' do
      fail 'mock data present' if @test_api_wrapper.mock_configurations != []
      comp_obj = @test_obj.dup
      @test_obj.load
      @test_obj.compare?(comp_obj).should eql true
    end

    loadable_attrs = RcbuBackupObjTestHelpers.get_all_attributes
    # Pop BackupConfigurationName, it's the search key and as such must match label; can't change it
    loadable_attrs.delete('BackupConfigurationName')
    # Pop BackupConfigurationId, it's set by the mocked API and requires a unique test
    loadable_attrs.delete('BackupConfigurationId')
    loadable_attrs.each do |attr|
      it "loads #{attr} into a class instance variable" do
        test_value = "Test #{attr} Value"
        @test_api_wrapper.create_config( 'BackupConfigurationName' => @test_label,
                                         attr                      => test_value,
                                         )
        @test_obj.load
        @test_obj.send(attr).should eql test_value
      end
    end

    it 'loads BackupConfigurationId into a class instance variable' do
      @test_api_wrapper.create_config( 'BackupConfigurationName' => @test_label )
      @test_api_wrapper.mock_configurations.length.should eql 1
      @test_obj.load
      @test_obj.BackupConfigurationId.should eql @test_api_wrapper.mock_configurations[0]['BackupConfigurationId']
    end

    # Spirit: Testing for code fragility / future breakage from API updates
    it 'doesn\'t error when provided with unknown keys' do
      @test_api_wrapper.create_config( 'BackupConfigurationName' => @test_label,
                                       'RackSpaceRules'          => true,
                                       'DevOpsRocks'             => 'doublePlusYes',
                                       'Kittens'                 => 'mittens'
                                       )
      @test_obj.load
    end
  end

  describe 'update' do
    before :each do
      @test_label       = 'Test Label'
      @test_api_wrapper = RcbuBackupObjTestHelpers.test_api_wrapper
      @test_obj = Opscode::Rackspace::CloudBackup::RcbuBackupObj.new(@test_label, @test_api_wrapper)
    end

    setters = RcbuBackupObjTestHelpers.get_settable_attributes
    RcbuBackupObjTestHelpers.get_all_attributes.each do |attr|
      test_variable = "update(#{attr}) Test Variable"

      if setters.include?(attr)
        it "updates settable attribute #{attr}" do
          @test_obj.update(attr => test_variable)
          @test_obj.send(attr).should eql test_variable
        end
      else
        it "does update non-settable #{attr}" do
          expect { @test_obj.update(attr => test_variable) }.to raise_exception
        end
      end
    end
  end

  describe 'to_hash' do
    before :each do
      @test_label       = 'Test Label'
      @test_api_wrapper = RcbuBackupObjTestHelpers.test_api_wrapper
      @test_obj = Opscode::Rackspace::CloudBackup::RcbuBackupObj.new(@test_label, @test_api_wrapper)
    end

    it 'returns a hash of all_attributes when no argument is given' do
      @test_obj.to_hash().keys.should eql @test_obj.all_attributes
    end

    # For this test looping over all_attributes is really overkill
    # So let's pick the variables that have defaults in the constructor and call it good.
    it 'returns correct values in the hash' do
      targets = %w(BackupConfigurationName MachineAgentId Inclusions Exclusions)
      hash_data = @test_obj.to_hash(targets)
      targets.each do |attr|
        hash_data[attr].should eql @test_obj.send(attr)
      end
    end
  end

  describe 'save' do
    before :each do
      @test_label       = 'Test Label'
      @test_api_wrapper = RcbuBackupObjTestHelpers.test_api_wrapper
      @test_obj = Opscode::Rackspace::CloudBackup::RcbuBackupObj.new(@test_label, @test_api_wrapper)
      fail 'mock data present' if @test_api_wrapper.mock_configurations != []
    end

    it 'creates new configurations' do
      fail 'BackupConfigurationId set' unless @test_obj.BackupConfigurationId.nil?
      @test_obj.save
      @test_api_wrapper.mock_configurations.length.should eql 1
    end

    it 'loads API details after creating new configurations' do
      fail 'BackupConfigurationId set' unless @test_obj.BackupConfigurationId.nil?
      @test_obj.save
      @test_api_wrapper.mock_configurations.length.should eql 1
      @test_obj.BackupConfigurationId.should_not eql nil
    end

    it 'updates existing configurations' do
      fail 'BackupConfigurationId set' unless @test_obj.BackupConfigurationId.nil?
      @test_obj.save
      @test_api_wrapper.mock_configurations.length.should eql 1
      @test_obj.BackupConfigurationId.should_not eql nil

      # Deeply hooking into the underlying mock object to test this.
      orig_mock_api_data = @test_api_wrapper.mock_configurations[0].dup

      @test_obj.MachineAgentId = 'Test Machine Agent ID'
      @test_obj.NotifySuccess  = 'Test Notify Value'

      @test_obj.save
      @test_api_wrapper.mock_configurations.length.should eql 1
      @test_obj.BackupConfigurationId.should eql orig_mock_api_data['BackupConfigurationId']
      orig_mock_api_data['BackupConfigurationId'].should eql @test_api_wrapper.mock_configurations[0]['BackupConfigurationId']
      orig_mock_api_data.should_not eql @test_api_wrapper.mock_configurations[0]
    end
  end

  describe 'dup' do
    before :each do
      @test_label       = 'Test Label'
      @test_api_wrapper = RcbuBackupObjTestHelpers.test_api_wrapper
      @test_obj = Opscode::Rackspace::CloudBackup::RcbuBackupObj.new(@test_label, @test_api_wrapper)
      fail 'mock data present' if @test_api_wrapper.mock_configurations != []
    end

    direct_attrs = RcbuBackupObjTestHelpers.get_all_attributes.each do |attr|
      it "duplicates #{attr} value" do
        copy = @test_obj.dup
        copy.send(attr).should eql @test_obj.send(attr)
      end
    end

    # TODO: INCOMPLETE
  end
end


