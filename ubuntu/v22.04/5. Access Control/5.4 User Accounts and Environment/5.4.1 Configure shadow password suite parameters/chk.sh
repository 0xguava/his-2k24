#!/bin/bash

check_pass_max_days() {
  echo -e "- Checking PASS_MAX_DAYS in /etc/login.defs:"
  pass_max_days_check=$(grep -Pi -- '^\h*PASS_MAX_DAYS\h+\d+\b' /etc/login.defs)

  if [[ "$pass_max_days_check" =~ "PASS_MAX_DAYS" ]]; then
    pass_max_days_value=$(echo "$pass_max_days_check" | awk '{print $2}')
    if [[ "$pass_max_days_value" -le 365 && "$pass_max_days_value" -gt 0 ]]; then
      echo -e "\t- Audit result: **PASS** [PASS_MAX_DAYS is set to $pass_max_days_value days]"
    else
      echo -e "\t- Audit result: **FAIL** [PASS_MAX_DAYS is not compliant]"
    fi
  else
    echo -e "\t- Audit result: **FAIL** [PASS_MAX_DAYS not found in /etc/login.defs]"
  fi
}

check_user_pass_max_days() {
  echo -e "- Checking all users' PASS_MAX_DAYS:"
  user_check=$(awk -F: '($2~/^\$.+\$/) {if($5 > 365 || $5 < 1)print "User: " $1 " PASS_MAX_DAYS: " $5}' /etc/shadow)

  if [[ -n "$user_check" ]]; then
    echo -e "\t- Audit result: **FAIL** [Non-compliant users found]"
    echo "$user_check"
  else
    echo -e "\t- Audit result: **PASS** [All users' PASS_MAX_DAYS are compliant]"
  fi
}

check_pass_min_days() {
  echo -e "- Checking PASS_MIN_DAYS in /etc/login.defs:"
  pass_min_days_check=$(grep -Pi -- '^\h*PASS_MIN_DAYS\h+\d+\b' /etc/login.defs)

  if [[ "$pass_min_days_check" =~ "PASS_MIN_DAYS" ]]; then
    pass_min_days_value=$(echo "$pass_min_days_check" | awk '{print $2}')
    if [[ "$pass_min_days_value" -gt 0 ]]; then
      echo -e "\t- Audit result: **PASS** [PASS_MIN_DAYS is set to $pass_min_days_value days]"
    else
      echo -e "\t- Audit result: **FAIL** [PASS_MIN_DAYS is not compliant]"
    fi
  else
    echo -e "\t- Audit result: **FAIL** [PASS_MIN_DAYS not found in /etc/login.defs]"
  fi
}

check_user_pass_min_days() {
  echo -e "- Checking all users' PASS_MIN_DAYS:"
  user_check=$(awk -F: '($2~/^\$.+\$/) {if($4 < 1)print "User: " $1 " PASS_MIN_DAYS: " $4}' /etc/shadow)

  if [[ -n "$user_check" ]]; then
    echo -e "\t- Audit result: **FAIL** [Non-compliant users found]"
    echo "$user_check"
  else
    echo -e "\t- Audit result: **PASS** [All users' PASS_MIN_DAYS are compliant]"
  fi
}


# Check PASS_WARN_AGE in /etc/login.defs
check_pass_warn_age() {
  echo -e "- Checking PASS_WARN_AGE in /etc/login.defs:"
  pass_warn_age_check=$(grep -Pi -- '^\h*PASS_WARN_AGE\h+\d+\b' /etc/login.defs)

  if [[ "$pass_warn_age_check" =~ "PASS_WARN_AGE" ]]; then
    pass_warn_age_value=$(echo "$pass_warn_age_check" | awk '{print $2}')
    if [[ "$pass_warn_age_value" -ge 7 ]]; then
      echo -e "\t- Audit result: **PASS** [PASS_WARN_AGE is set to $pass_warn_age_value days]"
    else
      echo -e "\t- Audit result: **FAIL** [PASS_WARN_AGE is not compliant]"
    fi
  else
    echo -e "\t- Audit result: **FAIL** [PASS_WARN_AGE not found in /etc/login.defs]"
  fi
}

# Check all users' PASS_WARN_AGE in /etc/shadow
check_user_pass_warn_age() {
  echo -e "- Checking all users' PASS_WARN_AGE:"
  user_check=$(awk -F: '($2~/^\$.+\$/) {if($6 < 7)print "User: " $1 " PASS_WARN_AGE: " $6}' /etc/shadow)

  if [[ -n "$user_check" ]]; then
    echo -e "\t- Audit result: **FAIL** [Non-compliant users found]"
    echo "$user_check"
  else
    echo -e "\t- Audit result: **PASS** [All users' PASS_WARN_AGE are compliant]"
  fi
}

# Run checks
check_encryption_method() {
  echo -e "- Checking ENCRYPT_METHOD in /etc/login.defs:"
  
  # Search for ENCRYPT_METHOD and verify if it's SHA512 or YESCRYPT
  encryption_check=$(grep -Pi -- '^\h*ENCRYPT_METHOD\h+(SHA512|yescrypt)\b' /etc/login.defs)

  if [[ -n "$encryption_check" ]]; then
    echo -e "\t- Audit result: **PASS** [ENCRYPT_METHOD is compliant: $encryption_check]"
  else
    echo -e "\t- Audit result: **FAIL** [ENCRYPT_METHOD is not compliant or not found]"
  fi
}


# Check INACTIVE in useradd -D
check_inactive_setting() {
  echo -e "- Checking INACTIVE setting in useradd -D:"
  inactive_check=$(useradd -D | grep INACTIVE)

  if [[ "$inactive_check" =~ "INACTIVE=45" ]]; then
    echo -e "\t- Audit result: **PASS** [INACTIVE is set to 45 days]"
  else
    echo -e "\t- Audit result: **FAIL** [INACTIVE is not set to 45 days]"
  fi
}

# Check all users' INACTIVE value in /etc/shadow
check_user_inactive() {
  echo -e "- Checking all users' INACTIVE value:"
  inactive_check=$(awk -F: '($2~/^\$.+\$/) {if($7 > 45 || $7 < 0)print "User: " $1 " INACTIVE: " $7}' /etc/shadow)

  if [[ -n "$inactive_check" ]]; then
    echo -e "\t- Audit result: **FAIL** [Non-compliant users found]"
    echo "$inactive_check"
  else
    echo -e "\t- Audit result: **PASS** [All users' INACTIVE values are compliant]"
  fi
}


# Verify no users have a last password change set in the future
verify_last_password_change() {
  echo -e "- Checking users' last password change date:"
  
  while IFS= read -r l_user; do
    l_change=$(date -d "$(chage --list $l_user | grep '^Last password change' | cut -d: -f2 | grep -v 'never$')" +%s)
    
    # If last password change is greater than the current date, it indicates an error
    if [[ "$l_change" -gt "$(date +%s)" ]]; then
      echo -e "\t- Audit result: **FAIL** [User: \"$l_user\" last password change was \"$(chage --list $l_user | grep '^Last password change' | cut -d: -f2)\", but it is set in the future]"
    fi
  done < <(awk -F: '$2~/^\$.+\$/{print $1}' /etc/shadow)
}

check_pass_max_days
check_user_pass_max_days
check_pass_min_days
check_user_pass_min_days
check_pass_warn_age
check_user_pass_warn_age
check_encryption_method
check_inactive_setting
check_user_inactive
verify_last_password_change
