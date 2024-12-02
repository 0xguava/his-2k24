#!/bin/bash

passwd-chk(){
  echo -e "- Bootloader's configuration check for bootloader password:"
  if [[ -n "$(grep "^set superusers" /boot/grub/grub.cfg)" ]] && [[ -n "$(awk -F. '/^\s*password/ {print $1"."$2"."$3}' /boot/grub/grub.cfg)" ]] ; then
    echo -e "\t- Audit result: **PASS** [bootloader password is set]"
  else
    echo -e "\t- Audit result: **FAIL** [bootloader password isn't set]"
  fi
}

access-chk(){
  local output_p=''
  local output_f=''
  local logvr=1
  userID=$(stat -Lc %u /boot/grub/grub.cfg)
  groupID=$(stat -Lc %g /boot/grub/grub.cfg)
  perm=$(stat -Lc %a /boot/grub/grub.cfg)

  echo -e "- Access check for bootloader's config file:"
  if [[ "$userID" -eq 0 ]]; then
    output_p="$output_p\n\t - bootloader's config file is owned by 'root' user."
  else
    output_f="$output_f\n\t - bootloader's config file isn't owned by 'root' user."
    logvr=0
  fi

  if [[ "$groupID" -eq 0 ]]; then
    output_p="$output_p\n\t - bootloader's config file is owned by 'root' group."
  else
    output_f="$output_f\n\t - bootloader's config file isn't owned by 'root' group."
    logvr=0
  fi

  if [[ "$perm" -eq 600 ]]; then
    output_p="$output_p\n\t - File permissions are configured correctly."
  else
    output_f="$output_f\n\t - File permissions aren't configured correctly."
    logvr=0
  fi

  if [[ $logvr -eq 0 ]]; then
    echo -e "\t- Audit result: **FAIL** [Access to bootloader's config isn't configured properly]"
    echo -e "\t- Reason: $output_f"
  else
    echo -e "\t- Audit result: **PASS** [Access to bootloader's config is configured properly]"
    echo -e "\t- Reason: $output_p"
  fi
}

passwd-chk
access-chk
