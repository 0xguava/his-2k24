#!/bin/bash

check_pam_unix_config(){
  echo -e "- Checking pam_unix.so configuration in /etc/pam.d/common-* files:"

  # Run the grep command to find pam_unix.so in common-* files
  pam_unix_config=$(grep -P -- '\bpam_unix\.so\b' /etc/pam.d/common-*)

  if [[ -z "$pam_unix_config" ]]; then
    echo -e "\t- Audit result: **FAIL** [pam_unix.so is not found in /etc/pam.d/common-* files]"
  else
    echo -e "\t- Audit result: **PASS** [pam_unix.so is correctly configured in the common-* files]"
    echo -e "\t- Configuration found:\n$pam_unix_config"
  fi
}

check_pam_faillock(){
  echo -e "- Checking pam_faillock.so configuration in /etc/pam.d/common-auth and /etc/pam.d/common-account:"

  # Run the grep command to find pam_faillock.so in common-auth and common-account
  pam_faillock_config=$(grep -P -- '\bpam_faillock\.so\b' /etc/pam.d/common-{auth,account})

  if [[ -z "$pam_faillock_config" ]]; then
    echo -e "\t- Audit result: **FAIL** [pam_faillock.so is not found in /etc/pam.d/common-auth or /etc/pam.d/common-account]"
  else
    echo -e "\t- Audit result: **PASS** [pam_faillock.so is correctly configured in the files]"
    echo -e "\t- Configuration found:\n$pam_faillock_config"
  fi
}

check_pam_pwquality(){
  echo -e "- Checking pam_pwquality.so configuration in /etc/pam.d/common-password:"

  # Run the grep command to find pam_pwquality.so in common-password
  pam_pwquality_config=$(grep -P -- '\bpam_pwquality\.so\b' /etc/pam.d/common-password)

  if [[ -z "$pam_pwquality_config" ]]; then
    echo -e "\t- Audit result: **FAIL** [pam_pwquality.so is not found in /etc/pam.d/common-password]"
  else
    echo -e "\t- Audit result: **PASS** [pam_pwquality.so is correctly configured in /etc/pam.d/common-password]"
    echo -e "\t- Configuration found:\n$pam_pwquality_config"
  fi
}


check_pam_pwhistory(){
  echo -e "- Checking pam_pwhistory.so configuration in /etc/pam.d/common-password:"

  # Run the grep command to find pam_pwhistory.so in common-password
  pam_pwhistory_config=$(grep -P -- '\bpam_pwhistory\.so\b' /etc/pam.d/common-password)

  if [[ -z "$pam_pwhistory_config" ]]; then
    echo -e "\t- Audit result: **FAIL** [pam_pwhistory.so is not found in /etc/pam.d/common-password]"
  else
    echo -e "\t- Audit result: **PASS** [pam_pwhistory.so is correctly configured in /etc/pam.d/common-password]"
    echo -e "\t- Configuration found:\n$pam_pwhistory_config"
  fi
}

check_pam_unix_config
check_pam_faillock
check_pam_pwquality
check_pam_pwhistory
