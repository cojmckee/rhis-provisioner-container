#!/bin/bash

ansiblever="2.4"
secretsdir=""
groupvarsdir=""
hostvarsdir=""
inventorydir=""

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -a|--ansible-ver)
            ansiblever="$2"
            shift # Shift past the value
            ;;
        -s|--secrets-dir)
            secretsdir="$2"
            shift # Shift past the value
            ;;
        -g|--group-vars-dir)
            groupvarsdir="$2"
            shift # Shift past the value
            ;;
        -h|--host-vars-dir)
            hostvarsdir="$2"
            shift # Shift past the value
            ;;
        -i|--inventory-dir)
            inventorydir="$2"
            shift # Shift past the value
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
    shift # Shift past the option
done

echo
echo "Launching the rhis-provisioner container with the following parameters:"
echo "secrets-dir: $secretsdir"
echo "group-vars-dir: $groupvarsdir"
echo "host-vars-dir: $hostvarsdir"
echo "group-vars-dir: $inventorydir"
echo "ansible-ver: $ansiblever"
echo

if [[ $secretsdir == "" ]]; then
  echo "ERROR: A secrets directory is required - exiting."
  exit 1
fi

if [[ $groupvarsdir == "" || $hostvarsdir == "" || $inventorydir == "" ]]; then
  echo "A custom configuration was not provided, using example.ca demo configuration."
  
  podman run -it -v $secretsdir:/rhis/vars/vault:Z --hostname provisioner localhost/rhis-provisioner-9-$ansiblever:latest
  
  # Quietly restore the SELinux context 
  restorecon -FRq $secretsdir
  
else
  echo "Mounting custom configuration"

  podman run -it -v $secretsdir:/rhis/vars/vault:Z \
               -v $groupvarsdir:/rhis/vars/group_vars:Z \
               -v $hostvarsdir:/rhis/vars/host_vars:Z \
               -v $inventorydir:/rhis/vars/external_inventory:Z \
               --hostname provisioner \
               localhost/rhis-provisioner-9-$ansiblever:latest
  
  # Quietly restore the SELinux context 
  restorecon -FRq $secretsdir
  restorecon -FRq $groupvarsdir
  restorecon -FRq $hostvarsdir
  restorecon -FRq $inventorydir
fi
