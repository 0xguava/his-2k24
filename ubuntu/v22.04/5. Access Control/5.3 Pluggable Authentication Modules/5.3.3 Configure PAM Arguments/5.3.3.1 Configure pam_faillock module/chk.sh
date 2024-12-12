#!/bin/bash

check_deny_value(){
  echo -e "- Checking deny argument configuration in /etc/security/faillock.conf and /etc/pam.d/common-auth:"

  # Check if deny value in /etc/security/faillock.conf is 5 or less
  deny_value=$(grep -Pi -- '^\h*deny\h*=\h*[1-5]\b' /etc/security/faillock.conf)

  if [[ -n "$deny_value" ]]; then
    echo -e "\t- Audit result: **PASS** [deny value is set between 1 and 5 in /etc/security/faillock.conf]"
  else
    echo -e "\t- Audit result: **FAIL** [deny value is not set correctly in /etc/security/faillock.conf]"
  fi

  # Check if deny value in /etc/pam.d/common-auth is greater than 5 or set to 0
  deny_pam_value=$(grep -Pi -- '^\h*auth\h+(requisite|required|sufficient)\h+pam_faillock\.so\h+([^#\n\r]+\h+)?deny\h*=\h*(0|[6-9]|[1-9][0-9]+)\b' /etc/pam.d/common-auth)

  if [[ -n "$deny_pam_value" ]]; then
    echo -e "\t- Audit result: **FAIL** [deny value in /etc/pam.d/common-auth is incorrectly set to 0 or greater than 5]"
  else
    echo -e "\t- Audit result: **PASS** [deny value in /etc/pam.d/common-auth is correctly configured]"
  fi
}

check_unlock_time(){
  echo -e "- Checking unlock_time argument configuration in /etc/security/faillock.conf and /etc/pam.d/common-auth:"

  # Check unlock_time in /etc/security/faillock.conf
  unlock_time_conf=$(grep -Pi -- '^\h*unlock_time\h*=\h*(0|9[0-9][0-9]|[1-9][0-9]{3,})\b' /etc/security/faillock.conf)

  if [[ -n "$unlock_time_conf" ]]; then
    echo -e "\t- Audit result: **PASS** [unlock_time is correctly set in /etc/security/faillock.conf]"
    echo -e "\t- Configuration found:\n$unlock_time_conf"
  else
    echo -e "\t- Audit result: **FAIL** [unlock_time is not set correctly in /etc/security/faillock.conf]"
  fi

  # Check unlock_time in /etc/pam.d/common-auth
  unlock_time_pam_conf=$(grep -Pi -- '^\h*auth\h+(requisite|required|sufficient)\h+pam_faillock\.so\h+([^#\n\r]+\h+)?unlock_time\h*=\h*([1-9]|[1-9][0-9]|[1-8][0-9][0-9])\b' /etc/pam.d/common-auth)

  if [[ -n "$unlock_time_pam_conf" ]]; then
    echo -e "\t- Audit result: **FAIL** [unlock_time is incorrectly set in /etc/pam.d/common-auth]"
  else
    echo -e "\t- Audit result: **PASS** [unlock_time is correctly configured in /etc/pam.d/common-auth]"
  fi
}

check_root_unlock_time(){
  echo -e "- Checking even_deny_root and root_unlock_time configuration in /etc/security/faillock.conf and /etc/pam.d/common-auth:"

  # Check if even_deny_root or root_unlock_time is set in /etc/security/faillock.conf
  faillock_conf=$(grep -Pi -- '^\h*(even_deny_root|root_unlock_time\h*=\h*\d+)\b' /etc/security/faillock.conf)

  if [[ -n "$faillock_conf" ]]; then
    echo -e "\t- Audit result: **PASS** [even_deny_root or root_unlock_time is configured in /etc/security/faillock.conf]"
    echo -e "\t- Configuration found:\n$faillock_conf"
  else
    echo -e "\t- Audit result: **FAIL** [even_deny_root or root_unlock_time is not set in /etc/security/faillock.conf]"
  fi

  # Check if root_unlock_time is set to a value less than 60
  root_unlock_time_conf=$(grep -Pi -- '^\h*root_unlock_time\h*=\h*([1-9]|[1-5][0-9])\b' /etc/security/faillock.conf)

  if [[ -n "$root_unlock_time_conf" ]]; then
    echo -e "\t- Audit result: **FAIL** [root_unlock_time is incorrectly set to less than 60 in /etc/security/faillock.conf]"
  else
    echo -e "\t- Audit result: **PASS** [root_unlock_time is correctly set to 60 or more in /etc/security/faillock.conf]"
  fi

  # Check if root_unlock_time is set in /etc/pam.d/common-auth (should be 60 or more)
  root_unlock_time_pam_conf=$(grep -Pi -- '^\h*auth\h+([^#\n\r]+\h+)pam_faillock\.so\h+([^#\n\r]+\h+)?root_unlock_time\h*=\h*([1-9]|[1-5][0-9])\b' /etc/pam.d/common-auth)

  if [[ -n "$root_unlock_time_pam_conf" ]]; then
    echo -e "\t- Audit result: **FAIL** [root_unlock_time is incorrectly set to less than 60 in /etc/pam.d/common-auth]"
  else
    echo -e "\t- Audit result: **PASS** [root_unlock_time is correctly set to 60 or more in /etc/pam.d/common-auth]"
  fi
}


check_deny_value
check_unlock_time
check_root_unlock_time
