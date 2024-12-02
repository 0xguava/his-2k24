#!/bin/bash

tmpfs_part=('/tmp' '/dev/shm')
fs_parts=('/home' '/var' '/var/tmp' '/var/log' '/var/log/audit')

fix_tmpfs_part(){
  if [[ -n $(findmnt -kn $@) && -n $(grep $@ /etc/fstab) ]]; then 
    echo -e "\t- No remedition required for $@ partition."
  else
    echo -e "tmpfs\t$@\ttmpfs\tdefaults,rw,nosuid,nodev,noexec,relatime\t0\t0" | tee -a /etc/fstab 
    echo -e "\t- Remedition done for $@"
  fi
}

fix_tmpfs_opts(){
  part=$(echo $@ | sed 's/\//\\\//g')
  if [[ -z $(findmnt -kn $@ | grep nodev) ]];then
    sed "/$part/c\tmpfs\t/tmp\ttmpfs\tdefaults,rw,nosuid,nodev,noexec,relatime\t0\t0" -i /etc/fstab
    mount -o remount $@
    echo -e "\t- [nodev,nosuid,noexec] options correctly set for $@"
  elif [[ -z $(findmnt -kn $@ | grep -v nosuid) ]];then
    sed "/$part/c\tmpfs\t/tmp\ttmpfs\tdefaults,rw,nosuid,nodev,noexec,relatime\t0\t0" -i /etc/fstab
    mount -o remount $@
    echo -e "\t- [nodev,nosuid,noexec] options correctly set for $@"
  elif [[ -z $(findmnt -kn $@ | grep -v noexec) ]];then
    sed "/$part/c\tmpfs\t/tmp\ttmpfs\tdefaults,rw,nosuid,nodev,noexec,relatime\t0\t0" -i /etc/fstab
    mount -o remount $@
    echo -e "\t- [nodev,nosuid,noexec] options correctly set for $@"
  else
    echo -e "\t- No remedition required for $@. All options are set properly."
  fi 
}

# fix_sep_part '/tmp'
fix_sep_part(){
  if [[ -n $(findmnt -kn /var) ]]; then
    echo -e "\t- No remedition required for $@ partition."
  else
    echo -e "\t- Create a new partition for $@ and create its entry in fstab."
  fi
}

echo -e "\n\nRemedition for filesystem partitions:"
for fs in "$@"; do
  echo -e "\n$fs partition:"
  if [[ "$fs" == "/tmp" || "$fs" == "/dev/shm" ]]; then
    fix_tmpfs_part $fs
    fix_tmpfs_opts $fs
  else
    fix_sep_part $fs
  fi
done
