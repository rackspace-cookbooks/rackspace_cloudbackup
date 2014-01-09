#!/usr/bin/env python
#Copyright 2014 Rackspace Hosting, Inc.

#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

"""
exit codes:
  0 - success
  1 - generic failure
  2 - bootstrap.json key error
  3 - registration failure
  4 - System unregistered
"""

import argparse
import json
import sys
import subprocess

def get_registration_status(args, bootstrapFile = '/etc/driveclient/bootstrap.json'):
    """
    Reads registration status from /etc/driveclient/bootstrap.json
    Returns True if registered, False otherwise
    """

    try:
        data = json.load(open(bootstrapFile))
    except:
        print "ERROR: Exception opening %s" % bootstrapFile
        sys.exit(1)
        
    try:
        return data["IsRegistered"]
    except KeyError:
        # This key should always be present, as it
        # is in the default bootstrap.json file
        # Fail if missing.
        if args.verbose:
            print "ERROR: Missing key IsRegistered in %s" % (key, bootstrapFile)
        sys.exit(2)

def perform_registration(args):
    """
    Call the driveclient utilities to register with the server"
    """
    process = subprocess.Popen(("/usr/local/bin/driveclient -c -u %s -k %s" % (args.apiuser, args.apikey)),
                               stdout=subprocess.PIPE, shell=True)
    retVal = process.wait()
    if retVal != 0:
        if args.verbose:
            print "ERROR: driveclient -c returned %d" % retVal
        sys.exit(3)

    # Bounce the driveclient daemon to reload new bootstrap file
    process = subprocess.Popen("/etc/init.d/driveclient restart", stdout=subprocess.PIPE, shell=True)
    retVal = process.wait()
    if retVal != 0:
        if args.verbose:
            print "ERROR: driveclient restart returned %d" % retVal
        sys.exit(3)

def parse_arguments():
    parser = argparse.ArgumentParser(description='Verifies DriveClient registration status',
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--apiuser', '-u', required=False, help='Api username')
    parser.add_argument('--apikey', '-a', required=False, help='Account api key')
    parser.add_argument('--register', '-r', action='store_true', default=False, help="Attempt DriveClient registration if unregistered")
    parser.add_argument('--verbose', '-v', action='store_true', help='Enable verbose output')

    args = parser.parse_args()

    if args.register:
        if not args.apiuser or not args.apikey:
            print "ERROR: --apiuser and --apikey are required when --register is set"
            print "See help (-h) for further details"
            sys.exit(1)

    return args

def main():
    args = parse_arguments()

    status = get_registration_status(args)

    if status is True:
        if args.verbose:
            print "INFO: driveclient is registered"
        sys.exit(0)

    if args.register is False:
        if args.verbose:
            print "INFO: driveclient is NOT registered"
        sys.exit(4)
        

    # Register agent
    perform_registration(args)

    # Verify registration
    status = get_registration_status(args)

    if status is True:
        if args.verbose:
            print "INFO: driveclient registration successful"
        sys.exit(0)

    if args.verbose:
        print "ERROR: Driveclient unregistered after successful configure run"
    sys.exit(3)
    

if __name__ == '__main__':
    main()
