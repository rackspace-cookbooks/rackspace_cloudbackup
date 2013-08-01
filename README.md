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

Here's an example of some environment variables for if it used turbolift

    "rackspace_cloud_backup": {
      "backup_cron_hour": "*",
      "backup_cron_day": "*",
      "rackspace_username": "exampleuser",
      "rackspace_endpoint": "dfw",
      "backup_locations": [
        "/root/files",
        "/etc"
      ],
      "backup_cron_user": "root",
      "backup_cron_weekday": "*",
      "backup_container": "ubuntu-test-turbolift",
      "rackspace_apikey": "lolnopenotgonnahappen",
      "backup_cron_month": "*",
      "backup_cron_minute": "50"
    }


Contributing
------------
Please see https://github.com/rackspace-cookbooks/contributing for how to contribute.

License and Authors
-------------------
License: Apache 2.0
Authors: Matthew Thode (prometheanfire)
