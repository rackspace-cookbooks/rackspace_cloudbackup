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
#

require 'json'

module Opscode
  module Rackspace
    # CloudBackup helper modules, this file adds methods to the namespace for handling bootstrap data
    module CloudBackup
      # gather_bootstrap_data:  Read the bootstrap file and return loaded information.
      def gather_bootstrap_data(bootstrap_file)
        begin
          bootstrap_raw_data = open(bootstrap_file).read
        rescue
          Chef::Log.fatal("Error reading #{bootstrap_file}")
          return nil
        end

        begin
          bootstrap_data = JSON.parse(bootstrap_raw_data)
        rescue
          Chef::Log.fatal("Error parsing #{bootstrap_file}")
          return nil
        end

        return bootstrap_data
      end
      module_function :gather_bootstrap_data
    end
  end
end
