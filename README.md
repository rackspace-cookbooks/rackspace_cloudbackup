rackspace-cloud-backup Cookbook
===============================
This cookbook will install the Rackspace Cloud Backup agent and register it based on the credentials found in
node['rackspace_cloud_backup']['username'] and node['rackspace_cloud_backup']['apikey']
------------
Requires Apt and Yum

Attributes
----------
default[:rackspace_cloud_backup][:rackspace_username] = nil
default[:rackspace_cloud_backup][:rackspace_apikey] = nil

Usage
-----
#### rackspace-cloud-backup::default
Just set the environment variables for the rackspace_username and rackspace_apikey attributes

Contributing
------------
Please see https://github.com/rackspace-cookbooks/contributing for how to contribute.

License and Authors
-------------------
License: Apache 2.0
Authors: Matthew Thode (prometheanfire)
