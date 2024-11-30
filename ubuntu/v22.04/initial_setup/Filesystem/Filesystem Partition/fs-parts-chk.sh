#!/bin/bash

logvr=-1;

chk_sep_part(){
  if [[ -n $(findmnt -kn $@) && -n $(grep $@ /etc/fstab) ]]; then
    echo -e "\t- Seperate partion for $@ exists."; logvr=1
  else
    echo -e "\t- Seperate Partion for $@ does not exists."; logvr=0
  fi
}

chk_nodev(){
  if [[ -n $(findmnt -kn $@ | grep nodev) ]]; then
    echo -e "\t- 'nodev' option is set on $@ partition."; logvr=1
  else 
    echo -e "\t- 'nodev' option is not set on $@ partition."; logvr=0
  fi
}

chk_nosuid(){
  if [[ -n $(findmnt -kn $@ | grep nosuid) ]]; then 
    echo -e "\t- 'nosuid' option is set on $@ partition."; logvr=1 
  else 
    echo -e "\t- 'nosuid' option is not set on $@ partition."; logvr=0 
  fi
}

chk_noexec(){
  if [[ -n $(findmnt -kn $@ | grep noexec) ]]; then 
    echo -e "\t- 'noexec' option is set on $@ partition."; logvr=1 
  else
    echo -e "\t- 'noexec' option is not set on $@ partition."; logvr=0
  fi
}

fs_parts=('/tmp' '/dev/shm' '/home' '/var' '/var/tmp' '/var/log' '/var/log/audit')

echo -e "\n\nAudit for filesystem partitions."
for parts in "${fs_parts[@]}";do 
  echo -e "\n$parts partition:"
  chk_sep_part "$parts"
  chk_nodev "$parts"
  chk_nosuid "$parts"
  chk_noexec "$parts"
  [[ "$logvr" -eq 0 ]] && echo -e "\t# Result: **FAIL** for [$parts]" || echo -e "\t# Result: **PASS** for [$parts]"
done
