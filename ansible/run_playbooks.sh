#!/bin/bash

# $1 is playbook to run string
# $2 is inventory string
# $3 is filename string

function run_playbook () {
  echo "Running: ansible-playbook $1 -i $2 at $(date)"
  ansible-playbook $1 -i $2 >> $3 2>&1
  if [ $? -eq 0 ]; then
    echo "Success."
  else
    echo "Unsuccessful playbook. Error Code $?"
    exit 1
  fi
}

echo "Beginning Installation at $(date)."

run_playbook provision_hostsfile.yaml inventory.py install.out
run_playbook provision_core_servers.yaml inventory.py install.out
run_playbook update_resolv.yaml inventory.py install.out
run_playbook provision_common_packages.yaml inventory.py install.out
run_playbook provision_java_packages.yaml inventory.py install.out
run_playbook provision_zookeeper_servers.yaml inventory.py install.out
run_playbook provision_hadoop_servers.yaml inventory.py install.out
run_playbook provision_kafka_servers.yaml inventory.py install.out
run_playbook provision_mysql_servers.yaml inventory.py install.out
run_playbook provision_druid_servers.yaml inventory.py install.out
run_playbook provision_tranquility_servers.yaml inventory.py install.out
run_playbook provision_metabase_servers.yaml inventory.py install.out

echo "Ending Installation at $(date)."
