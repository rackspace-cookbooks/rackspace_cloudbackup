require 'serverspec'
require 'pathname'

set :backend, :exec

RSpec.configure do |c|
  c.before :all do
  end
end

# Define a helper module for this test suite.
module SpecHelpers
  def crontab_path
    case os[:family].downcase
    when 'redhat', 'centos'
      return '/var/spool/cron/root'
    when 'ubuntu', 'debian'
      return '/var/spool/cron/crontabs/root'
    else
      fail "Unknown OS \"#{os[:family]}\""
    end
  end
  module_function :crontab_path
end
