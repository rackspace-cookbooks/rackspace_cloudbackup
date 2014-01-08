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
  2 - auth failure
  3 - backup api error
  4 - /etc/driveclient/bootstrap.json error
"""


import argparse
import json
import httplib
from sys import exit as sysexit
import time
from datetime import datetime

def cloud_auth(args):
    """
    Authenticate and return authentication details via returned dict
    """
    token = ""
    authurl = 'identity.api.rackspacecloud.com'
    jsonreq = json.dumps({'auth': {'RAX-KSKEY:apiKeyCredentials':
                                  {'username': args.apiuser,
                                   'apiKey': args.apikey}}})
    if args.verbose:
        print 'JSON REQUEST: ' + jsonreq

    #make the request
    connection = httplib.HTTPSConnection(authurl, 443)
    if args.verbose:
        connection.set_debuglevel(1)
    headers = {'Content-type': 'application/json'}
    connection.request('POST', '/v2.0/tokens', jsonreq, headers)
    json_response = json.loads(connection.getresponse().read())
    connection.close()

    #process the request
    if args.verbose:
        print 'JSON decoded and pretty'
        print json.dumps(json_response, indent=2)
    try:
        token = json_response['access']['token']['id']
        if args.verbose:
            print 'Token:\t\t', token
    except(KeyError, IndexError):
        #print 'Error while getting answers from auth server.'
        #print 'Check the endpoint and auth credentials.'
        sysexit(2)
    finally:
        return token


def get_machine_agent_id(args, required_keys = None):
    """
    Loads the agent ID from disk (/etc/driveclient/bootstrap.json)
    """

    tries = args.retries
    while True:
        data = json.load(open('/etc/driveclient/bootstrap.json'))

        missing_key = False
        for key in required_keys:
            if not data.has_key(key):
                if args.verbose:
                    print "WARNING: Missing key %s in bootstrap.json" % (key)
                    
                missing_key = True
                break
        
        if missing_key:
            tries -= 1
            if tries <= 0:
                debugOut = {
                    'fail_type': 'bootstrap.json Key Failure',
                    'date': datetime.now().strftime('%Y/%m/%d %H:%M:%S'),
                    'machine_info': machine_info }
                open('/etc/driveclient/failed-setup-backups.json', 'a+b').write(json.dumps(debugOut))
            
                if args.verbose:
                    print 'Failing due to missing key from /etc/driveclient/bootstrap.json.\nLoaded data:'
                    print machine_info
                sysexit(4)

            time.sleep(args.retrydelay)
        else:
            return data

def create_backup_plan(args, token, machine_info):
    """
    Creates a basic backup plan based on the directory given
    """
    req = {"BackupConfigurationName": "Backup for %s, backing up %s" % (args.ip, args.directory),
           "MachineAgentId": machine_info['AgentId'],
           "IsActive": True,
           "VersionRetention": 30,
           "MissedBackupActionId": 1,
           "Frequency": "Manually",
           "StartTimeHour": None,
           "StartTimeMinute": None,
           "StartTimeAmPm": None,
           "DayOfWeekId": None,
           "HourInterval": None,
           "TimeZoneId": "UTC",
           "NotifyRecipients": args.email,
           "NotifySuccess": False,
           "NotifyFailure": True,
           "Inclusions": [
            {"FilePath": args.directory,
             "FileItemType": "Folder"
             }
            ],
           "Exclusions": []
           }
    jsonreq = json.dumps(req)

    if args.verbose:
        print 'JSON REQUEST: ' + jsonreq

    tries = args.retries
    errors = []
    while True:
        #make the request
        connection = httplib.HTTPSConnection('backup.api.rackspacecloud.com', 443)
        if args.verbose:
            connection.set_debuglevel(1)
        headers = {'Content-type': 'application/json',
                   'X-Auth-Token': token}
        path = "/v1.0/%s/backup-configuration" % machine_info['AccountId']
            
        connection.request('POST', path, jsonreq, headers)

        #process the request
        response = connection.getresponse()
        status = response.status
        json_response = json.loads(response.read())
        connection.close()
        if status is not 200:
            errors.append(status)
            
            # Fail immediately on Client Error (4xx) responses
            # TODO: Should we just fail immediately if status < 500?
            if status >= 400 and status <= 499:
                tries = 0
            else:
                tries -= 1

            if tries is 0:
                debugOut = {
                    'fail_type': 'API Request Failure',
                    'date': datetime.now().strftime('%Y/%m/%d %H:%M:%S'),
                    'responses': errors,
                    'req': req }

                open('/etc/driveclient/failed-setup-backups.json', 'a+b').write(json.dumps(debugOut))

                if args.verbose:
                    print 'Failing due to bad API responses.\nDebug:'
                    print debugOut

                sysexit(3)
        else:
            try:
                return json_response['BackupConfigurationId']
            except(KeyError, IndexError):
                #print 'Error while getting answers from auth server.'
                #print 'Check the endpoint and auth credentials.'
                sysexit(2)

        time.sleep(args.retrydelay)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Gets auth data via json',
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--apiuser', '-u', required=True, help='Api username')
    parser.add_argument('--apikey', '-a', required=True, help='Account api key')
    parser.add_argument('--directory', '-d', required=True, help='Directory to back up')
    parser.add_argument('--email', '-e', required=True, help='Email to send notices to')
    parser.add_argument('--ip', '-i', required=True, help='IP address to add to the name')
    parser.add_argument('--verbose', '-v', action='store_true', help='Turn up verbosity to 10')
    parser.add_argument('--retries', '-r', action='store', default=3, help="Number of times to retry a task before failing", type=int)
    parser.add_argument('--retrydelay', '-R', action='store', default=1, help="Number of seconds to delay between retries", type=int)

    #populate needed variables
    args = parser.parse_args()
    token = cloud_auth(args)
    machine_info = get_machine_agent_id(args, ['AccountId'])

    #create the backup plan
    backup_id = create_backup_plan(args, token, machine_info)

    register_cmd = "python /etc/driveclient/auth.py -u %s -a %s" % (args.apiuser, args.apikey)
    trigger_cmd = "curl -X POST -H \"X-Auth-Token: $(%s)\" -H \"Content-type: application/json\" \"https://backup.api.rackspacecloud.com/v1.0/%s/backup/action-requested\" -d \'{\"Action\": \"StartManual\", \"Id\": %s}\'" % (register_cmd, machine_info['AccountId'], backup_id)
    print trigger_cmd
