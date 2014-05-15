#
# Cookbook Name:: rackspace_cloudbackup
#
# Copyright 2014, Rackspace, US, Inc.
# Copyright 2012-2013, Seth Vargo
# Copyright 2012, CustomInk, LLC
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
# Originally from https://github.com/customink-webops/hostsfile/blob/master/spec/spec_helper.rb

# This file is seperate from rspec_helper as chefspec triggers berkshelf which calls out to the web,
# breaking API mock tests.

require 'chefspec'
require 'chefspec/berkshelf'

require_relative 'supported_platforms.rb'

# Sets common RSpec.configure option
require_relative 'rspec_helper.rb'

# ChefSpec specific options
RSpec.configure do |c|
  c.log_level = :warn
end
