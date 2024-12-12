#!/bin/bash

check_nullok_argument(){
  echo -e "- Checking for nullok argument in pam_unix.so module in PAM configuration files:"

  # Search for pam_unix.so without nullok argument
  nullok_check=$(grep -PH -- '^\h*^\h*[^#\n\r]+\h+pam_unix\.so\b' /etc/pam.d/common-{password,auth,account,session,session-noninteractive} | grep -Pv -- '\bnullok\b')

  if [[ -n "$nullok_check" ]]; then
    echo -e "\t- Audit result: **PASS** [nullok argument is not set in pam_unix.so]"
  else
    echo -e "\t- Audit result: **FAIL** [nullok argument is present in pam_unix.so]"
  fi
}

check_remember_argument(){
  echo -e "- Checking for remember argument in pam_unix.so module in PAM configuration files:"

  # Search for pam_unix.so without remember argument
  remember_check=$(grep -PH -- '^\h*^\h*[^#\n\r]+\h+pam_unix\.so\b' /etc/pam.d/common-{password,auth,account,session,session-noninteractive} | grep -Pv -- '\bremember=\d+\b')

  if [[ -n "$remember_check" ]]; then
    echo -e "\t- Audit result: **PASS** [remember argument is not set in pam_unix.so]"
  else
    echo -e "\t- Audit result: **FAIL** [remember argument is present in pam_unix.so]"
  fi
}

check_password_hashing(){
  echo -e "- Checking for strong password hashing algorithm on pam_unix.so module:"

  # Search for pam_unix.so with sha512 or yescrypt
  hashing_check=$(grep -PH -- '^\h*password\h+([^#\n\r]+)\h+pam_unix\.so\h+([^#\n\r]+\h+)?(sha512|yescrypt)\b' /etc/pam.d/common-password)

  if [[ -n "$hashing_check" ]]; then
    echo -e "\t- Audit result: **PASS** [Strong password hashing algorithm (sha512/yescrypt) is set]"
  else
    echo -e "\t- Audit result: **FAIL** [No strong password hashing algorithm found]"
  fi
}

check_use_authtok(){
  echo -e "- Checking for 'use_authtok' in pam_unix.so module:"

  # Search for pam_unix.so with use_authtok
  use_authtok_check=$(grep -PH -- '^\h*password\h+([^#\n\r]+)\h+pam_unix\.so\h+([^#\n\r]+\h+)?use_authtok\b' /etc/pam.d/common-password)

  if [[ -n "$use_authtok_check" ]]; then
    echo -e "\t- Audit result: **PASS** [use_authtok is set]"
  else
    echo -e "\t- Audit result: **FAIL** [use_authtok is not set]"
  fi
}


check_nullok_argument
check_remember_argument
check_password_hashing
check_use_authtok
