TESTING WARNING
===============
Testing currently has gaps and there are cut corners in the code.
These *should* be flagged with TODO blocks.

rackspace_cloudbackup libraries
===============================

This cookbook has multiple tiers of libraries:

* HWRPs
* Classes supporting recipes and the HWRPs that interact with the API
* Test support libraries

HWRPs
-----

HWRPs were used instead of LWRPs as it easily enabled testing with RSpec.
Due to how all the moving parts of this cookbook interact HWRPs are not intended for direct consumption by outside cookbooks.
Outside cookbooks should use the node variables documented in the readme.

| File | Purpose |
| ---- | ------- |
| configure_cloud_backup_hwrp.rb | Configures a RCBU backup job in the API |
| register_agent_hwrp.rb | Registers the DriveClient agent on the server to the RCBU infrastructure |

Support Classes
---------------

A number of underlying classes are used to interact with the API, provide object classes, and deduplicate code.

| Class | File | Purpose |
| ----- | ---- | ------- |
| [Module] | gather_bootstrap_data.rb | Provides the gather_bootstrap_data method which loads the agent bootstrap config file off a server |
| RcbuApiWrapper | RcbuApiWrapper.rb | Provides minimal bindings to the RCBU API as no official RCBU Ruby SDK exists as of v1.0.0 |
| RcbuBackupObj | RcbuBackupObj.rb   | Provides a object class representing a backup object in the API |
| RcbuBackupWrapper | RcbuBackupWrapper.rb | Wrap the underlying objects and provide an object class directly consumable by the HWRP. Essentially a HWRP to RcbuBackupObj glue class. |
| RcbuCache | RcbuCache.rb | This class implements a in-memory cache object used by higher level classes.  This allows for object caching cutting down on redundant API calls. |

Testing Classes
---------------

These classes are for testing and are not used under normal operation

| File | Purpose |
| ---- | ------- |
| MockRcbuApiWrapper.rb | Provides a mocked RcbuApiWrapper class for testing that emulates RcbuApiWrapper |
| matchers.rb | Implements custom ChefSpec matchers for the HWRPs. |