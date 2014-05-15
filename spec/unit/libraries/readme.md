Warning:

These tests use two test gems which don't play nice with each other as coded:

* WebMock: This gem is used to mock the RCBU API.  The tests disable net access to ensure all API calls are mocked.

* ChefSpec: This gem is used to test Chef code.  It triggers Berkshelf which calls out to the internet.

When ChefSpec is required at the global namespace (anywhere!) it will override RSpec.
The tests that use webmock will then use ChefSpec in place of RSpec.
WebMock will disable web requests, and ChefSpec will try to call out to the internet via it's calling of Berkshelf.
This will result in false failures as WebMock reports the unmocked calls to api.opscode.com and github.com

Rather than whitelisting anything that ChefSpec/Berkshelf may want to hit, including of ChefSpec is instead done within the test scope.
This seems to solve the problem reliably.