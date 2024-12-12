#!/bin/bash

check_pwhistory(){
  echo -e "- Checking pam_pwhistory configuration in /etc/pam.d/common-password:"

  # Search for the pam_pwhistory.so line with the remember option in common-password
  pwhistory_line=$(grep -Psi -- '^\h*password\h+[^#\n\r]+\h+pam_pwhistory\.so\h+([^#\n\r]+\h+)?remember=\d+\b' /etc/pam.d/common-password)

  if [[ -n "$pwhistory_line" && $(echo "$pwhistory_line" | grep -oP 'remember=\K\d+') -ge 24 ]]; then
    echo -e "\t- Audit result: **PASS** [pam_pwhistory.so with remember=24 or more is configured correctly]"
  else
    echo -e "\t- Audit result: **FAIL** [pam_pwhistory.so is either missing or the remember value is less than 24]"
  fi
}

check_pwhistory_root_enforce(){
  echo -e "- Checking enforce_for_root configuration in pam_pwhistory line in /etc/pam.d/common-password:"

  # Search for the pam_pwhistory.so line with enforce_for_root in common-password
  pwhistory_line=$(grep -Psi -- '^\h*password\h+[^#\n\r]+\h+pam_pwhistory\.so\h+([^#\n\r]+\h+)?enforce_for_root\b' /etc/pam.d/common-password)

  if [[ -n "$pwhistory_line" ]]; then
    echo -e "\t- Audit result: **PASS** [enforce_for_root argument is present in pam_pwhistory.so]"
  else
    echo -e "\t- Audit result: **FAIL** [enforce_for_root argument is missing in pam_pwhistory.so]"
  fi
}

check_pwhistory_use_authtok(){
  echo -e "- Checking use_authtok configuration in pam_pwhistory line in /etc/pam.d/common-password:"

  # Search for the pam_pwhistory.so line with use_authtok in common-password
  pwhistory_line=$(grep -Psi -- '^\h*password\h+[^#\n\r]+\h+pam_pwhistory\.so\h+([^#\n\r]+\h+)?use_authtok\b' /etc/pam.d/common-password)

  if [[ -n "$pwhistory_line" ]]; then
    echo -e "\t- Audit result: **PASS** [use_authtok argument is present in pam_pwhistory.so]"
  else
    echo -e "\t- Audit result: **FAIL** [use_authtok argument is missing in pam_pwhistory.so]"
  fi
}


check_pwhistory
check_pwhistory_root_enforce
check_pwhistory_use_authtok
