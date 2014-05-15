rackspace_cloudbackup Cookbook
===============================

NOTE: v1.0.0 is a major rewrite with breaking changes.  Please review this readme for new usage and check the changelog
-----------------------------------------------------------------------------------------------------------------------

# Description

This cookbook provides backups to Rackspace Cloud Files.
On Rackspace Cloud Servers it will install and configure the Rackspace Cloud Backup (RCBU) service for backups.
On cloud the RCBU agent will be installed and registered and each backup location configured as a unique backup job.
Jobs are currently triggered via Cron for timing compatibility.

Non-Rackspace Cloud servers currently unsupported and will fail convergance.

# General Requirements
* Chef 11
* A Rackspace Cloud Hosting account is required to use this tool.  And a valid `username` and `api_key` are required to authenticate into your account.

This cookbook will install the EPEL repository on RHEL based systems.

# Usage

## Credentials

API credentials are stored in the shared node['rackspace']['cloud_credentials'] hash.

| Attribute | Description | Required |
| --------- | ----------- | -------- |
| node['rackspace']['cloud_credentials']['username'] | Rackspace API username | Yes |
| node['rackspace']['cloud_credentials']['api_key']  | Rackspace API key | Yes |

## Primary Configuration Hash List

node['rackspace_cloudbackup']['backups'] is a list of hashes, each list entry representing a location to back up.
The hash format is as follows:

```
{
   label: Unique backup label*
   location: filesystem path to backup (Required)
   comment:   Some comment (optional)
   enable:    Enable the backup, Boolean, Optional with default of true
   cloud: Hash of options specific to Rackspace Cloud Servers.  Format: {
      notify_email: Email address for notifications on Rackspace Cloud**
      version_retention: Retention value, see API documentation***
   }
   time: Time override hash for this backup in Cron format.  (Optional) Format: {
      day: Day of month to run backup
      month: Month to run backup
      hour: Hour to run backup
      minute: Minute to run backup
      weekday: Day of week to run backup
   }
   cron: Cron override hash for this backup.  (Optional) Format: {
      user:   User to run the job as
      mailto: Address to send error messages to
      path:   Cron path
      shell:  Cron shell
      home:   Cron home
  }
}
```

Notes:
- *   This backup is the unique identifier for the job.  It defaults to ```"Backup for #{node['ipaddress']}, backing up #{job['location']}"``` for compatability with earlier versions.  Changing the label may result in orphaned or lost backups.
- **  Mail sent to this address will come from a Rackspace RCBU server, not the local server.  It must be a valid address.
- *** [3.3.1. Create backup configuration](http://docs.rackspace.com/rcbu/api/v1.0/rcbu-devguide/content/POST_createBackupConfiguration_v1.0__tenant_id__backup-configuration_backupConfig.html)


Example:

```ruby
# Note that some further defaults are required.  See below for a complete example.
node.default['rackspace_cloudbackup']['backups'] =
  [
   { location: "/var/www",
     comment:  "Web Content Backup",
     cloud: {
       # Override the default to send notifications to webmaster
       # See below for default values
       notify_email: "webmaster@yourdomain.com"
     }
   },

   { location: "/etc",
     time: {
       # Only backup the server configuration on the first of the month at midnight
       day:     1,
       month:   '*',
       hour:    0,
       minute:  0,
       weekday: '*'
     }
   },

   # This is the minimal block, a single location with all other options default
   { location: "/home" },
  ]
```

## Default Values

In addition to the node['rackspace_cloudbackup']['backups'] hash a node['rackspace_cloudbackup']['backups_defaults'] hash is provided for default node-wide job setting.
This allows deduplication of common settings in the primary configuration hash list.
See [attributes/default.rb](https://github.com/rackspace-cookbooks/rackspace-cloud-backup/blob/master/attributes/default.rb) for default values and further details.

### General settings
| Attribute | Purpose |
| --------- | ------- |
| node['rackspace']['datacenter'] | Datacenter to back up to, must match cloud server datacenter. |
| node['rackspace_cloudbackup']['backups_defaults']['cloud_notify_email']      | Email address for notifications on Rackspace Cloud   |
| node['rackspace_cloudbackup']['backups_defaults']['cloud_version_retention'] | Cloud version retention value, see API documentation |

### Time settings
| Attribute | Purpose |
| --------- | ------- |
| node['rackspace_cloudbackup']['backups_defaults']['time']['day']             | Default backup day, Cron format     |
| node['rackspace_cloudbackup']['backups_defaults']['time']['month']           | Default backup month, Cron format   |
| node['rackspace_cloudbackup']['backups_defaults']['time']['hour']            | Default backup hour, Cron format    |
| node['rackspace_cloudbackup']['backups_defaults']['time']['minute']          | Default backup minute, Cron format  |
| node['rackspace_cloudbackup']['backups_defaults']['time']['weekday']         | Default backup weekday, Cron format |

## Example Usage

Below is a complete example codeblock.

```ruby

# Define API values
node.default['rackspace']['cloud_credentials']['username'] = '{your api username}'
node.default['rackspace']['cloud_credentials']['api_key']  = '{your api key}'

# Set the default notification email
node.default['rackspace_cloudbackup']['backups_defaults']['cloud_notify_email'] = 'root@yourdomain.com'

# Define the backups
node.default['rackspace_cloudbackup']['backups'] =
  [
   { location: "/var/www",
     comment:  "Web Content Backup",
     cloud: {
       # Override the default to send notifications to webmaster
       notify_email: "webmaster@yourdomain.com"
     }
   },

   { location: "/etc",
     time: {
       # Only backup the server configuration on the first of the month at midnight
       day:     1,
       month:   '*',
       hour:    0,
       minute:  0,
       weekday: '*'
     }
   },

   # This is the minimal block, a single location with all other options default
   { location: "/home" },
  ]

# Remember that this must be called after all recipies which modify the hash have completed.
include_recipe 'rackspace_cloudbackup'
```

# Contributing

Please see https://github.com/rackspace-cookbooks/contributing for how to contribute.

# License and Authors

Authors:
- Matthew Thode (prometheanfire)
- Tom Noonan II

```
Copyright:: 2012 - 2014 Rackspace

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```