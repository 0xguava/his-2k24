#!/bin/bash

cron-chk() {
  echo -e "\n- Cron service check:"

  local output_p="" 
  local output_f="" 

  if command -v cron &>/dev/null || command -v crond &>/dev/null; then
    output_p+="\t- cron is installed\n"
  else
    output_f+="\t- cron is not installed\n"
    echo -e "\t- Audit result [Cron Service Check]: **FAIL**"
    echo -e "$output_f"
    return
  fi

  local is_enabled
  is_enabled=$(systemctl list-unit-files | awk '$1~/^crond?\.service/{print $2}')
  if [[ "$is_enabled" == "enabled" ]]; then
    output_p+="\t- cron service is enabled\n"
  else
    output_f+="\t- cron service is not enabled\n"
  fi

  local is_active
  is_active=$(systemctl list-units | awk '$1~/^crond?\.service/{print $3}')
  if [[ "$is_active" == "active" ]]; then
    output_p+="\t- cron service is active\n"
  else
    output_f+="\t- cron service is not active\n"
  fi

  if [[ -z "$output_f" ]]; then
    echo -e "\t- Audit result [Cron Service Check]: **PASS**"
    echo -e "$output_p"
  else
    echo -e "\t- Audit result [Cron Service Check]: **FAIL**"
    echo -e "$output_f"
  fi
}

cron-perm1-chk(){
  local output_p=''
  local output_f=''
  local logvr=1
  userID=$(stat -Lc %u /etc/$@)
  groupID=$(stat -Lc %g /etc/$@)
  perm=$(stat -Lc %a /etc/$@)

  echo -e "\n- Access check for /etc/$@ file:"
  if [[ "$userID" -eq 0 ]]; then
    output_p="$output_p\n\t - /etc/$@ is owned by 'root' user."
  else
    output_f="$output_f\n\t - /etc/$@ config file isn't owned by 'root' user."
    logvr=0
  fi

  if [[ "$groupID" -eq 0 ]]; then
    output_p="$output_p\n\t - /etc/$@ is owned by 'root' group."
  else
    output_f="$output_f\n\t - /etc/$@ isn't owned by 'root' group."
    logvr=0
  fi

  if [[ "$@" = "crontab" ]]; then
    if [[ "$perm" -eq 600 ]]; then
      output_p="$output_p\n\t - Permissions on /etc/$@ are configured correctly."
    else
      output_f="$output_f\n\t - Permissions on /etc/$@ aren't configured correctly."
      logvr=0
    fi
  else
    if [[ "$perm" -eq 700 ]]; then
      output_p="$output_p\n\t - Permissions on /etc/$@ are configured correctly."
    else
      output_f="$output_f\n\t - Permissions on /etc/$@ aren't configured correctly."
      logvr=0
    fi
  fi

  if [[ $logvr -eq 0 ]]; then
    echo -e "\t- Audit result: **FAIL** [Access to /etc/$@ isn't configured properly]"
    echo -e "\t- Reason: $output_f"
  else
    echo -e "\t- Audit result: **PASS** [Access to /etc/$@ is configured properly]"
    echo -e "\t- Reason: $output_p"
  fi
}

cron-perm2-chk() {
  echo -e "\n- Cron service check:"

  local output_p=""  # Stores PASS outputs
  local output_f=""  # Stores FAIL outputs

  # Check if cron is installed
  if command -v cron &>/dev/null || command -v crond &>/dev/null; then
    output_p+="\t- cron is installed\n"
  else
    output_f+="\t- cron is not installed\n"
    echo -e "\t- Audit result [Cron Service Check]: **FAIL**"
    echo -e "$output_f"
    return
  fi

  # Check /etc/cron.allow
  if [ -e "/etc/cron.allow" ]; then
    local cron_allow_stat
    cron_allow_stat=$(stat -Lc 'Access: (%a) Owner: (%U) Group: (%G)' /etc/cron.allow)
    local access owner group
    read -r access owner group <<< "$(echo $cron_allow_stat | awk -F '[()]' '{print $2, $4, $6}')"
    if [[ "$access" -le 640 && "$owner" == "root" && "$group" == "root" ]]; then
      output_p+="\t- /etc/cron.allow exists with correct permissions\n"
    else
      output_f+="\t- /etc/cron.allow permissions or ownership are incorrect\n"
    fi
  else
    output_f+="\t- /etc/cron.allow does not exist\n"
  fi

  # Check /etc/cron.deny
  if [ -e "/etc/cron.deny" ]; then
    local cron_deny_stat
    cron_deny_stat=$(stat -Lc 'Access: (%a) Owner: (%U) Group: (%G)' /etc/cron.deny)
    local access owner group
    read -r access owner group <<< "$(echo $cron_deny_stat | awk -F '[()]' '{print $2, $4, $6}')"
    if [[ "$access" -le 640 && "$owner" == "root" && "$group" == "root" ]]; then
      output_p+="\t- /etc/cron.deny exists with correct permissions\n"
    else
      output_f+="\t- /etc/cron.deny permissions or ownership are incorrect\n"
    fi
  else
    output_p+="\t- /etc/cron.deny does not exist\n"
  fi

  # Print the audit result and details
  if [[ -z "$output_f" ]]; then
    echo -e "\t- Audit result [Cron Service Check]: **PASS**"
    echo -e "$output_p"
  else
    echo -e "\t- Audit result [Cron Service Check]: **FAIL**"
    echo -e "$output_f"
  fi
}

at-chk() {
  echo -e "\n- At service check:"

  local output_p=""
  local output_f=""

  if command -v at &>/dev/null; then
    output_p+="\t- 'at' is installed\n"
  else
    output_f+="\t- 'at' is not installed\n"
    echo -e "\t- Audit result [At Service Check]: **FAIL**"
    echo -e "$output_f"
    return
  fi

  if [ -e "/etc/at.allow" ]; then
    local at_allow_stat
    at_allow_stat=$(stat -Lc 'Access: (%a) Owner: (%U) Group: (%G)' /etc/at.allow)
    local access owner group
    read -r access owner group <<< "$(echo $at_allow_stat | awk -F '[()]' '{print $2, $4, $6}')"
    if [[ "$access" -le 640 && "$owner" == "root" && ( "$group" == "daemon" || "$group" == "root" ) ]]; then
      output_p+="\t- /etc/at.allow exists with correct permissions\n"
    else
      output_f+="\t- /etc/at.allow permissions or ownership are incorrect\n"
    fi
  else
    output_f+="\t- /etc/at.allow does not exist\n"
  fi

  if [ -e "/etc/at.deny" ]; then
    local at_deny_stat
    at_deny_stat=$(stat -Lc 'Access: (%a) Owner: (%U) Group: (%G)' /etc/at.deny)
    local access owner group
    read -r access owner group <<< "$(echo $at_deny_stat | awk -F '[()]' '{print $2, $4, $6}')"
    if [[ "$access" -le 640 && "$owner" == "root" && ( "$group" == "daemon" || "$group" == "root" ) ]]; then
      output_p+="\t- /etc/at.deny exists with correct permissions\n"
    else
      output_f+="\t- /etc/at.deny permissions or ownership are incorrect\n"
    fi
  else
    output_p+="\t- /etc/at.deny does not exist\n"
  fi

  if [[ -z "$output_f" ]]; then
    echo -e "\t- Audit result [At Service Check]: **PASS**"
    echo -e "$output_p"
  else
    echo -e "\t- Audit result [At Service Check]: **FAIL**"
    echo -e "$output_f"
  fi
}

cron-chk

cron-chk
crons=('crontab' 'cron.daily' 'cron.hourly' 'cron.monthly' 'cron.weekly' 'cron.d')
for c in "${crons[@]}"; do 
  cron-perm1-chk $c 
done

cron-perm2-chk
at-chk
