#!/bin/bash

installed-chk(){
  echo -e "- apparmor install check:"
  if [[ -z "$(dpkg-query -s apparmor)" ]]; then
    echo -e "\t- Audit result: **FAIL** [apparmor isn't installed]"
  else
    echo -e "\t- Audit result: **PASS** [apparmor is installed]"
  fi

  echo -e "- apparmor-utils install check:"
  if [[ -z "$(dpkg-query -s apparmor-utils 2> /dev/null)" ]]; then
    echo -e "\t- Audit result: **FAIL** [apparmor-utils isn't installed]"
  else
    echo -e "\t- Audit result: **PASS** [apparmor-utils is installed]"
  fi
}

bootloader-chk(){
  local output_p=''
  local output_f=''
  local logvr=''
  echo -e "- apparmor's bootloader configuration check:"
  if [[ -n "$(grep "^\s*linux" /boot/grub/grub.cfg | grep -v "apparmor=1")" ]]; then
    output_f="$output_f\n\t - 'apparmor=1' is not set in GRUB_CMDLINE_LINUX"
    logvr=0
  else
    output_p="$output_p\n\t - 'apparmor=1' is set in GRUB_CMDLINE_LINUX"
    logvr=1
  fi

  if [[ -n "$(grep "^\s*linux" /boot/grub/grub.cfg | grep -v "security=apparmor" )" ]]; then
    output_f="$output_f\n\t - 'security=apparmor' is not set in GRUB_CMDLINE_LINUX"
    logvr=0
  else
    output_p="$output_p\n\t - 'security=apparmor' is set in GRUB_CMDLINE_LINUX"
    logvr=1
  fi

  if [[ "$logvr" -eq 0 ]]; then
    echo -e "\t- Audit result: **FAIL** [apparmor isn't enabled in bootloader configuration]"
    echo -e "\t- Reason: $output_f"
  else
    echo -e "\t- Audit result: **PASS** [apparmor is enabled in bootloader configuration]"
    echo -e "\t- Reason: $output_p"
  fi
}

profiles-chk(){
  local output_p=''
  local output_f=''
  local logvr=''
  echo -e "- apparmor in profiles check:"
  p_loaded=$(apparmor_status | grep 'profiles.*loaded' | grep -o '.*[0-9]')
  p_enforce=$(apparmor_status | grep 'profiles.*enforce' | grep -o '.*[0-9]')
  u_process=$(apparmor_status | grep 'processes.*unconfined' | grep -o '.*[0-9]')

  if [[ "$p_loaded" -eq "$p_enforce" ]]; then
    output_p="$output_p\n\t - $(apparmor_status | grep -E 'profiles.*loaded')\n\t - $(apparmor_status | grep -E 'profiles.*enforce')"
    logvr=1
  else
    output_f="$output_f\n\t - $(apparmor_status | grep -E 'profiles.*loaded')\n\t - $(apparmor_status | grep -E 'profiles.*enforce')"
    logvr=0
  fi

  if [[ "$u_process" -eq 0 ]]; then
    output_p="$output_p\n\t - no processes are unconfined"
    logvr=1
  else
    output_f="$output_f\n\t - $(apparmor_status | grep 'processes.*unconfined')"
    logvr=0
  fi

  if [[ "$logvr" -eq 0 ]]; then
    echo -e "\t- Audit result: **FAIL** [apparmor profiles loaded but aren't in enforce mode]"
    echo -e "\t- Reason: $output_f"
  else
    echo -e "\t- Audit result: **PASS** [apparmor profiles loaded and are in enforce mode]"
    echo -e "\t- Reason: $output_p"
  fi
}

installed-chk
bootloader-chk
profiles-chk
