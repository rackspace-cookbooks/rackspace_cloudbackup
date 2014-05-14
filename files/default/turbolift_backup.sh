#!/bin/bash
# turbolift_backup.sh: Wrapper around turbolift to simplify Cron calls.
#
# Copyright 2014 Rackspace Hosting, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# usage: Print usage to stdout
# Arguments: NONE
function usage {
    echo "turbolift_backup.sh: Wrapper around turbolift to simplify Cron calls"
    echo "USAGE: turbolift_backup.sh -u [API Username] -k [API Key] -d [Datacenter]"
    echo -e "\t-u: Rackspace API username"
    echo -e "\t-k: Rackspace API key"
    echo -e "\t-d: Rackspace datacenter to back up to (DFW, IAD, ORD, etc...)"
    echo -e "\t-c: Rackspace CloudFiles container to back up to"
    echo -e "\t-l: Location (path) to backup"
    echo -e "\t-D: Disable the backup"
    echo -e "\t-s: Log to syslog"
    echo -e "\t-v: Be verbose"
}

# print_helper: Helper function for printing output
# ARGUMENTS:
# $1: String to print
# $2: Location:
#       0: stdout
#       1: syslog
#       Default: stderr
function print_helper {
    case $2 in
	0)
	    echo "${1}"
	    ;;
	1)
	    logger "turbolift_backup.sh: ${1}"
	    ;;
	*)
	    echo "${1}" >&2
	    ;;
    esac
}

loglocation=0
verbose=0
disabled=0

while getopts "k:u:d:c:l:Dsv" opt; do
    case "${opt}" in
	k)
	    apikey=${OPTARG}
	    ;;
	u)
	    apiuser=${OPTARG}
	    ;;
	d)
	    datacenter=${OPTARG}
	    ;;
	c)
	    container=${OPTARG}
	    ;;
	l)
	    location=${OPTARG}
	    ;;
	D)
	    disabled=1
	    ;;
	s)
	    loglocation=1
	    ;;
	v)
	    verbose=1
	    ;;
	    
	*)
	    usage
	    exit 1
	    ;;
    esac
done

if [ $verbose -eq 1 ]; then
    print_helper "Settings:" $loglocation
    print_helper "   API Key:    ${apikey}"  $loglocation
    print_helper "   API User:   ${apiuser}"  $loglocation
    print_helper "   Datacenter: ${datacenter}"  $loglocation
    print_helper "   Container:  ${container}"  $loglocation
    print_helper "   Location:   ${location}"  $loglocation
    print_helper "   Disabled:   ${disabled}"  $loglocation
    print_helper "   Log location: ${loglocation}"  $loglocation
fi

# Verify mandatory options are set
if [ -z "${apikey}" ]; then
    print_helper "ERROR: API Key not set" $loglocation
    exit 1
fi

if [ -z "${apiuser}" ]; then
    print_helper "ERROR: API Username not set" $loglocation
    exit 1
fi

if [ -z "${datacenter}" ]; then
    print_helper "ERROR: Datacenter not set" $loglocation
    exit 1
fi

if [ -z "${container}" ]; then
    print_helper "ERROR: Container not set" $loglocation
    exit 1
fi

if [ -z "${location}" ]; then
    print_helper "ERROR: Location not set" $loglocation
    exit 1
fi

if [ $disabled -eq 1 ]; then
    print_helper "Notice: Backup for ${location} disabled" $loglocation
    exit 0
fi

tarlocation=$(echo "$location" | sed -e 's|/|___|g')
time=$(date +%Y-%m-%d_%H:%M:%S)
turbolift --os-rax-auth $datacenter -u $username -a $apikey archive -s $location -c $container --verify --tar-name "${time} - ${tarlocation}"
retval=$?

if [ $retval -ne 0 ]; then
    print_helper "WARNING: Turbolift returned code ${retval} for location #{location}" $loglocation
    exit 1
else
    if [ $verbose -eq 1 ]; then
	print_helper "NOTICE: Turbolift returned code ${retval} for location #{location}" $loglocation
    fi
    exit 0
fi
