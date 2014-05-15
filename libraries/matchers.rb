# encoding: UTF-8
#
# Cookbook Name:: rackspace_cloudbackup
# Library:: matchers
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
#

if defined?(ChefSpec)
  # register_agent_hwrp
  def register_agent(label)
    ChefSpec::Matchers::ResourceMatcher.new(:rackspace_cloudbackup_register_agent, :register, label)
  end

  # configure_cloud_backup_hwrp
  def create_cloudbackup_configure_cloud_backup(label)
    ChefSpec::Matchers::ResourceMatcher.new(:rackspace_cloudbackup_configure_cloud_backup, :create, label)
  end

  def create_if_missing_cloudbackup_configure_cloud_backup(label)
    ChefSpec::Matchers::ResourceMatcher.new(:rackspace_cloudbackup_configure_cloud_backup, :create_if_missing, label)
  end

  def delete_cloudbackup_configure_cloud_backup(label)
    ChefSpec::Matchers::ResourceMatcher.new(:rackspace_cloudbackup_configure_cloud_backup, :delete, label)
  end
end
