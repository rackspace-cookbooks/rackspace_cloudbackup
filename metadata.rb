name             'rackspace_cloudbackup'
maintainer       'Rackspace US, Inc.'
maintainer_email 'rackspace-cookbooks@rackspace.com'
license          'Apache 2.0'
description      'Installs/Configures rackspace-cloud-backup'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))

version          '1.0.1'

recipe           'default', 'Installs and registers cloud backup'
recipe           'cloud', 'Installs and registers cloud backup, bypasses cloud provider check'
recipe           'cloud_agent', 'Registers the node as a cloud backup system'

depends 'apt', '~> 2.0'
depends 'yum', '~> 3.0'
depends 'ohai'
