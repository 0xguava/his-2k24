#!/bin/bash

check_difok(){
  echo -e "- Checking difok option configuration in /etc/security/pwquality.conf and /etc/security/pwquality.conf.d/*.conf:"

  # Check if difok is set to 2 or more in /etc/security/pwquality.conf and any additional .conf files in /etc/security/pwquality.conf.d/
  difok_conf=$(grep -Psi -- '^\h*difok\h*=\h*([2-9]|[1-9][0-9]+)\b' /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf)

  if [[ -n "$difok_conf" ]]; then
    echo -e "\t- Audit result: **PASS** [difok is set to 2 or more and conforms to local site policy]"
    echo -e "\t- Configuration found:\n$difok_conf"
  else
    echo -e "\t- Audit result: **FAIL** [difok is not set to 2 or more or doesn't conform to local site policy]"
  fi

  # Check if difok is incorrectly set to 0 or 1 in /etc/pam.d/common-password
  difok_pam_conf=$(grep -Psi -- '^\h*password\h+(requisite|required|sufficient)\h+pam_pwquality\.so\h+([^#\n\r]+\h+)?difok\h*=\h*([0-1])\b' /etc/pam.d/common-password)

  if [[ -n "$difok_pam_conf" ]]; then
    echo -e "\t- Audit result: **FAIL** [difok is set to 0 or 1 in /etc/pam.d/common-password]"
  else
    echo -e "\t- Audit result: **PASS** [difok is correctly set to 2 or more in /etc/pam.d/common-password]"
  fi
}

check_minlen(){
  echo -e "- Checking password length configuration in /etc/security/pwquality.conf and /etc/security/pwquality.conf.d/*.conf:"

  # Check if minlen is set to 14 or more in /etc/security/pwquality.conf and any additional .conf files in /etc/security/pwquality.conf.d/
  minlen_conf=$(grep -Psi -- '^\h*minlen\h*=\h*(1[4-9]|[2-9][0-9]|[1-9][0-9]{2,})\b' /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf)

  if [[ -n "$minlen_conf" ]]; then
    echo -e "\t- Audit result: **PASS** [minlen is set to 14 or more and conforms to local site policy]"
    echo -e "\t- Configuration found:\n$minlen_conf"
  else
    echo -e "\t- Audit result: **FAIL** [minlen is not set to 14 or more or doesn't conform to local site policy]"
  fi

  # Check for incorrect minlen value (less than 14) in /etc/pam.d/system-auth and /etc/pam.d/common-password
  minlen_pam_conf=$(grep -Psi -- '^\h*password\h+(requisite|required|sufficient)\h+pam_pwquality\.so\h+([^#\n\r]+\h+)?minlen\h*=\h*([0-9]|1[0-3])\b' /etc/pam.d/system-auth /etc/pam.d/common-password)

  if [[ -n "$minlen_pam_conf" ]]; then
    echo -e "\t- Audit result: **FAIL** [minlen is set to less than 14 in /etc/pam.d/system-auth or /etc/pam.d/common-password]"
  else
    echo -e "\t- Audit result: **PASS** [minlen is correctly set to 14 or more in /etc/pam.d/system-auth or /etc/pam.d/common-password]"
  fi
}

check_pwcomplexity(){
  echo -e "- Checking password complexity configuration in /etc/security/pwquality.conf and /etc/security/pwquality.conf.d/*.conf:"

  # Check if dcredit, ucredit, lcredit, and ocredit are not greater than 0 in /etc/security/pwquality.conf and additional .conf files
  pwcomplexity_conf=$(grep -Psi -- '^\h*(minclass|[dulo]credit)\b' /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf)

  if [[ -n "$pwcomplexity_conf" ]]; then
    echo -e "\t- Audit result: **PASS** [Complexity requirements conform to local site policy]"
    echo -e "\t- Configuration found:\n$pwcomplexity_conf"
  else
    echo -e "\t- Audit result: **FAIL** [Complexity requirements are not configured properly or don't conform to local site policy]"
  fi

  # Check for any overriding arguments in /etc/pam.d/common-password that may conflict with the configured complexity requirements
  pwcomplexity_pam_conf=$(grep -Psi -- '^\h*password\h+(requisite|required|sufficient)\h+pam_pwquality\.so\h+([^#\n\r]+\h+)?(minclass=\d*|[dulo]credit=-?\d*)\b' /etc/pam.d/common-password)

  if [[ -n "$pwcomplexity_pam_conf" ]]; then
    echo -e "\t- Audit result: **FAIL** [Complexity configuration in /etc/pam.d/common-password is overriding local site policy]"
  else
    echo -e "\t- Audit result: **PASS** [No overriding complexity configuration in /etc/pam.d/common-password]"
  fi
}



check_maxrepeat(){
  echo -e "- Checking maxrepeat configuration in /etc/security/pwquality.conf and /etc/security/pwquality.conf.d/*.conf:"

  # Check if maxrepeat is set to 3 or less, but not 0, in /etc/security/pwquality.conf and additional .conf files
  maxrepeat_conf=$(grep -Psi -- '^\h*maxrepeat\h*=\h*[1-3]\b' /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf)

  if [[ -n "$maxrepeat_conf" ]]; then
    echo -e "\t- Audit result: **PASS** [maxrepeat is configured to 3 or less]"
    echo -e "\t- Configuration found:\n$maxrepeat_conf"
  else
    echo -e "\t- Audit result: **FAIL** [maxrepeat is either not configured properly, is 0, or exceeds 3]"
  fi

  # Check for any overriding arguments in /etc/pam.d/common-password
  maxrepeat_pam_conf=$(grep -Psi -- '^\h*password\h+(requisite|required|sufficient)\h+pam_pwquality\.so\h+([^#\n\r]+\h+)?maxrepeat\h*=\h*(0|[4-9]|[1-9][0-9]+)\b' /etc/pam.d/common-password)

  if [[ -n "$maxrepeat_pam_conf" ]]; then
    echo -e "\t- Audit result: **FAIL** [maxrepeat is overridden in /etc/pam.d/common-password or is not configured properly]"
  else
    echo -e "\t- Audit result: **PASS** [maxrepeat is not overridden in /etc/pam.d/common-password]"
  fi
}


check_maxsequence(){
  echo -e "- Checking maxsequence configuration in /etc/security/pwquality.conf and /etc/security/pwquality.conf.d/*.conf:"

  # Check if maxsequence is set to 3 or less, but not 0, in /etc/security/pwquality.conf and additional .conf files
  maxsequence_conf=$(grep -Psi -- '^\h*maxsequence\h*=\h*[1-3]\b' /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf)

  if [[ -n "$maxsequence_conf" ]]; then
    echo -e "\t- Audit result: **PASS** [maxsequence is configured to 3 or less]"
    echo -e "\t- Configuration found:\n$maxsequence_conf"
  else
    echo -e "\t- Audit result: **FAIL** [maxsequence is either not configured properly, is 0, or exceeds 3]"
  fi

  # Check for any overriding arguments in /etc/pam.d/common-password
  maxsequence_pam_conf=$(grep -Psi -- '^\h*password\h+(requisite|required|sufficient)\h+pam_pwquality\.so\h+([^#\n\r]+\h+)?maxsequence\h*=\h*(0|[4-9]|[1-9][0-9]+)\b' /etc/pam.d/common-password)

  if [[ -n "$maxsequence_pam_conf" ]]; then
    echo -e "\t- Audit result: **FAIL** [maxsequence is overridden in /etc/pam.d/common-password or is not configured properly]"
  else
    echo -e "\t- Audit result: **PASS** [maxsequence is not overridden in /etc/pam.d/common-password]"
  fi
}

check_dictcheck(){
  echo -e "- Checking dictcheck option configuration in /etc/security/pwquality.conf and /etc/security/pwquality.conf.d/*.conf:"

  # Check if dictcheck is set to 0 (disabled) in /etc/security/pwquality.conf and additional .conf files
  dictcheck_conf=$(grep -Psi -- '^\h*dictcheck\h*=\h*0\b' /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf)

  if [[ -n "$dictcheck_conf" ]]; then
    echo -e "\t- Audit result: **FAIL** [dictcheck is set to 0 (disabled) in the configuration file]"
  else
    echo -e "\t- Audit result: **PASS** [dictcheck is not set to 0 in the configuration file]"
  fi

  # Check if dictcheck is set to 0 (disabled) in /etc/pam.d/common-password as a module argument
  dictcheck_pam_conf=$(grep -Psi -- '^\h*password\h+(requisite|required|sufficient)\h+pam_pwquality\.so\h+([^#\n\r]+\h+)?dictcheck\h*=\h*0\b' /etc/pam.d/common-password)

  if [[ -n "$dictcheck_pam_conf" ]]; then
    echo -e "\t- Audit result: **FAIL** [dictcheck is set to 0 (disabled) in /etc/pam.d/common-password]"
  else
    echo -e "\t- Audit result: **PASS** [dictcheck is not set to 0 in /etc/pam.d/common-password]"
  fi
}


check_enforcing(){
  echo -e "- Checking enforcing=0 option in /etc/security/pwquality.conf and /etc/security/pwquality.conf.d/*.conf:"

  # Check if enforcing=0 is set in /etc/security/pwquality.conf and additional .conf files
  enforcing_conf=$(grep -PHsi -- '^\h*enforcing\h*=\h*0\b' /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf)

  if [[ -n "$enforcing_conf" ]]; then
    echo -e "\t- Audit result: **FAIL** [enforcing=0 is set in the configuration file]"
  else
    echo -e "\t- Audit result: **PASS** [enforcing is not set to 0 in the configuration file]"
  fi

  # Check if enforcing=0 is set in /etc/pam.d/common-password for pam_pwquality module
  enforcing_pam_conf=$(grep -PHsi -- '^\h*password\h+[^#\n\r]+\h+pam_pwquality\.so\h+([^#\n\r]+\h+)?enforcing=0\b' /etc/pam.d/common-password)

  if [[ -n "$enforcing_pam_conf" ]]; then
    echo -e "\t- Audit result: **FAIL** [enforcing=0 is set in /etc/pam.d/common-password for pam_pwquality module]"
  else
    echo -e "\t- Audit result: **PASS** [enforcing is not set to 0 in /etc/pam.d/common-password for pam_pwquality module]"
  fi
}



check_enforce_for_root(){
  echo -e "- Checking enforce_for_root option in /etc/security/pwquality.conf and /etc/security/pwquality.conf.d/*.conf:"

  # Search for enforce_for_root in /etc/security/pwquality.conf and additional .conf files
  enforce_root_conf=$(grep -Psi -- '^\h*enforce_for_root\b' /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf)

  if [[ -n "$enforce_root_conf" ]]; then
    echo -e "\t- Audit result: **PASS** [enforce_for_root is enabled in the configuration file]"
  else
    echo -e "\t- Audit result: **FAIL** [enforce_for_root is not enabled in the configuration file]"
  fi
}

check_difok
check_minlen
check_pwcomplexity
check_maxrepeat
check_maxsequence
check_dictcheck
check_enforcing
check_enforce_for_root
