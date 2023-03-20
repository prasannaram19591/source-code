#!/bin/bash

source openRC
openstack server list --all-projects --long > serverlist.csv
