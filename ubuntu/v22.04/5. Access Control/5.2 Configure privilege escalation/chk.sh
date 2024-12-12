#!/bin/bash

sudo-chk(){
  echo -e "- Verifying sudo and sudo-ldap installation:"

  
  if dpkg-query -s sudo &>/dev/null; then
    echo -e "\t- Audit result: **PASS** [sudo is installed]"
  else
    echo -e "\t- Audit result: **FAIL** [sudo is not installed]"
  fi

  
  if dpkg-query -s sudo-ldap &>/dev/null; then
    echo -e "\t- Audit result: **PASS** [sudo-ldap is installed]"
  else
    echo -e "\t- Audit result: **FAIL** [sudo-ldap is not installed]"
  fi
}

sudo-pty-chk(){
  echo -e "- Verifying that sudo can only run commands from a pseudo terminal:"

  
  use_pty=$(grep -rPi -- '^\h*Defaults\h+([^#\n\r]+,)?use_pty(,\h*\h+\h*)*\h*(#.*)?$' /etc/sudoers*)
  if [[ -n "$use_pty" ]]; then
    echo -e "\t- Audit result: **PASS** [Defaults use_pty is set]"
    echo -e "\t  Found in: $use_pty"
  else
    echo -e "\t- Audit result: **FAIL** [Defaults use_pty is not set]"
  fi

  
  not_use_pty=$(grep -rPi -- '^\h*Defaults\h+([^#\n\r]+,)?!use_pty(,\h*\h+\h*)*\h*(#.*)?$' /etc/sudoers*)
  if [[ -n "$not_use_pty" ]]; then
    echo -e "\t- Audit result: **FAIL** [Defaults !use_pty is set]"
    echo -e "\t  Found in: $not_use_pty"
  else
    echo -e "\t- Audit result: **PASS** [Defaults !use_pty is not set]"
  fi
}

sudo-logfile-chk() {
  echo -e "- Verifying if sudo has a custom log file configured:"

  
  logfile_setting=$(grep -ri '^Defaults\s.*logfile\s*=' /etc/sudoers*)

  if [[ -n "$logfile_setting" ]]; then
    echo -e "\t- Audit result: **PASS** [Custom log file is configured]"
    echo -e "\t  Found in: $logfile_setting"

    
    logfile_path=$(echo "$logfile_setting" | sed -n 's/.*logfile[[:space:]]*=[[:space:]]*//p' | tr -d '"')
    if [[ "$logfile_path" == "/var/log/sudo.log" ]]; then
      echo -e "\t- Log file path matches the expected configuration: $logfile_path"
    else
      echo -e "\t- Log file path does not match the expected configuration. Found: $logfile_path"
    fi
  else
    echo -e "\t- Audit result: **FAIL** [Custom log file is not configured]"
  fi
}

sudo-nopasswd-chk() {
  echo "- Checking for 'NOPASSWD' entries in sudoers files:"

  
  nopasswd_entries=$(grep -r "^[^#].*NOPASSWD" /etc/sudoers*)

  if [[ -n "$nopasswd_entries" ]]; then
    echo -e "\t- Audit result: **FAIL** [NOPASSWD is configured]"
    echo -e "\t  Found in:"
    echo "$nopasswd_entries"
    echo -e "\n  **Remediation**:"
    echo "  - Open the listed file(s) and remove or modify the lines containing 'NOPASSWD'."
    echo "  - Ensure users are prompted for a password during privilege escalation."
  else
    echo -e "\t- Audit result: **PASS** [No NOPASSWD entries found]"
  fi
}

sudo-authenticate-chk() {
  echo "- Checking for '!authenticate' entries in sudoers files:"

  
  no_authenticate_entries=$(grep -r "^[^#].*!authenticate" /etc/sudoers*)

  if [[ -n "$no_authenticate_entries" ]]; then
    echo -e "\t- Audit result: **FAIL** ['!authenticate' is configured]"
    echo -e "\t  Found in:"
    echo "$no_authenticate_entries"
    echo -e "\n  **Remediation**:"
    echo "  - Open the listed file(s) and remove or modify the lines containing '!authenticate'."
    echo "  - Ensure users are required to re-authenticate for privilege escalation."
  else
    echo -e "\t- Audit result: **PASS** ['!authenticate' is not configured]"
  fi
}

sudo-timestamp-timeout-chk() {
  echo "- Checking for timestamp_timeout setting in sudoers files:"

  
  timeout_setting=$(grep -roP "timestamp_timeout=\K[0-9]*" /etc/sudoers*)

  if [[ -n "$timeout_setting" ]]; then
    if [[ "$timeout_setting" -gt 15 ]]; then
      echo -e "\t- Audit result: **FAIL** [timestamp_timeout is set to more than 15 minutes]"
      echo -e "\t  Found timestamp_timeout=$timeout_setting in /etc/sudoers or /etc/sudoers.d/*"
      echo -e "\n  **Remediation**:"
      echo "  - Open the /etc/sudoers or /etc/sudoers.d/* files and change timestamp_timeout to 15 or less."
    else
      echo -e "\t- Audit result: **PASS** [timestamp_timeout is set to $timeout_setting minutes]"
    fi
  else
    
    default_timeout=$(sudo -V | grep -i "Authentication timestamp timeout:" | awk '{print $5}')

    if [[ "$default_timeout" -gt 15 ]]; then
      echo -e "\t- Audit result: **FAIL** [Default timestamp_timeout is greater than 15 minutes, found $default_timeout minutes]"
      echo -e "\n  **Remediation**:"
      echo "  - Set 'timestamp_timeout=15' in the /etc/sudoers or /etc/sudoers.d/* files."
    else
      echo -e "\t- Audit result: **PASS** [Default timestamp_timeout is $default_timeout minutes]"
    fi
  fi
}

check_pam_wheel_config(){
  echo -e "- Checking pam_wheel.so configuration in /etc/pam.d/su:"

  
  pam_config=$(grep -Pi '^\h*auth\h+(?:required|requisite)\h+pam_wheel\.so\h+(?:[^#\n\r]+\h+)?((?!\2)(use_uid\b|group=\H+\b))\h+(?:[^#\n\r]+\h+)?((?!\1)(use_uid\b|group=\H+\b))(\h+.*)?$' /etc/pam.d/su)

  if [[ -z "$pam_config" ]]; then
    echo -e "\t- Audit result: **FAIL** [pam_wheel.so is not correctly configured in /etc/pam.d/su]"
    echo -e "\t- Reason: The configuration doesn't match 'auth required pam_wheel.so use_uid group=<group_name>'"
  else
    echo -e "\t- Audit result: **PASS** [pam_wheel.so is correctly configured]"
    echo -e "\t- Configuration: $pam_config"
  fi
}

check_group_membership(){
  echo -e "- Checking group membership for <group_name>:"

  
  group_name=$(echo "$pam_config" | grep -oP 'group=\K\S+')

  if [[ -z "$group_name" ]]; then
    echo -e "\t- Audit result: **FAIL** [No group specified in pam_wheel.so configuration]"
    return
  fi

  
  group_info=$(grep "^$group_name:" /etc/group)

  if [[ -z "$group_info" ]]; then
    echo -e "\t- Audit result: **FAIL** [Group $group_name does not exist in /etc/group]"
  else
    
    users=$(echo "$group_info" | cut -d: -f4)
    if [[ -z "$users" ]]; then
      echo -e "\t- Audit result: **PASS** [Group $group_name contains no users]"
    else
      echo -e "\t- Audit result: **FAIL** [Group $group_name contains users: $users]"
    fi
  fi
}

sudo-chk
sudo-pty-chk
sudo-logfile-chk
sudo-nopasswd-chk
sudo-authenticate-chk
sudo-timestamp-timeout-chk
check_pam_wheel_config
check_group_membership
