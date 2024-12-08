#!/bin/bash

cron-rem() {
  echo -e "- Cron service remediation:"

  local output_p=""
  local output_f=""

  # Check if cron is installed
  if command -v cron &>/dev/null || command -v crond &>/dev/null; then
    output_p+="\t- Cron is installed\n"
  else
    output_f+="\t- Cron is not installed\n"
  fi

  if command -v cron &>/dev/null; then
    # Identify cron service name (either cron or crond)
    local SERVICE_NAME=$(systemctl list-unit-files | awk '$1~/^crond?\.service/{print $1}' | head -n 1)

    if [ -z "$SERVICE_NAME" ]; then
      output_f+="\t- Cron service not found\n"
    else
      # Unmask, enable, and start cron service
      echo -e "\t- Unmasking, enabling, and starting $SERVICE_NAME..."
      systemctl unmask "$SERVICE_NAME" && output_p+="\t- Successfully unmasked $SERVICE_NAME\n" || output_f+="\t- Failed to unmask $SERVICE_NAME\n"
      systemctl --now enable "$SERVICE_NAME" && output_p+="\t- Successfully enabled and started $SERVICE_NAME\n" || output_f+="\t- Failed to enable and start $SERVICE_NAME\n"
    fi
  fi

  # Final audit result
  if [[ -z "$output_f" ]]; then
    echo -e "\t- Remediation result [Cron Service Check]: **SUCCESS**"
    echo -e "$output_p"
  else
    echo -e "\t- Remediation result [Cron Service Check]: **EveryThingisOK**"
    echo -e "$output_f"
  fi
}

cron-perm1-rem(){
  local chk=1
  userID=$(stat -Lc %u /etc/$@)
  groupID=$(stat -Lc %g /etc/$@)
  perm=$(stat -Lc %a /etc/$@)
  val=700
  
  [[ "$@" = "crontab" ]] && val=600

  [[ "$userID" -ne 0 ]] && chk=0  
  [[ "$groupID" -ne 0 ]] && chk=0  
  [[ "$perm" -ne  ]] && chk=0  
  
  echo -e "- Remediation for /etc/$@ access"
  if [[ "$chk" -eq 0 ]]; then
    chown root:root /etc/$@ 
    chmod $val /etc/$@ 
    echo -e "\t- Remediation: **SUCCESS**"
  else
    echo -e "\t- Remediation: Everything is **OK**"
  fi
}

cron-perm2-rem() {
  echo -e "- Cron configuration check:"

  local output_p=""
  local output_f=""

  # Check if cron is installed
  if command -v cron &>/dev/null || command -v crond &>/dev/null; then
    output_p+="\t- Cron is installed\n"
  else
    output_f+="\t- Cron is not installed\n"
  fi

  # /etc/cron.allow configuration
  if [ ! -e "/etc/cron.allow" ]; then
    touch /etc/cron.allow && output_p+="\t- Created /etc/cron.allow\n" || output_f+="\t- Failed to create /etc/cron.allow\n"
  else
    output_p+="\t- /etc/cron.allow already exists\n"
  fi

  chown root:root /etc/cron.allow && output_p+="\t- Set ownership of /etc/cron.allow to root:root\n" || output_f+="\t- Failed to set ownership of /etc/cron.allow\n"
  chmod 640 /etc/cron.allow && output_p+="\t- Set permissions of /etc/cron.allow to 640\n" || output_f+="\t- Failed to set permissions of /etc/cron.allow\n"

  # /etc/cron.deny configuration
  if [ -e "/etc/cron.deny" ]; then
    chown root:root /etc/cron.deny && output_p+="\t- Set ownership of /etc/cron.deny to root:root\n" || output_f+="\t- Failed to set ownership of /etc/cron.deny\n"
    chmod 640 /etc/cron.deny && output_p+="\t- Set permissions of /etc/cron.deny to 640\n" || output_f+="\t- Failed to set permissions of /etc/cron.deny\n"
  else
    output_p+="\t- /etc/cron.deny does not exist\n"
  fi

  # Final remediation result
  if [[ -z "$output_f" ]]; then
    echo -e "\t- Remediation result [Cron Configuration Check]: **SUCCESS**"
    echo -e "$output_p"
  else
    echo -e "\t- Remediation result [Cron Configuration Check]: **everythingisOK**"
    echo -e "$output_f"
  fi
}

cron-config-chk

cron-rem

crons=('crontab' 'cron.daily' 'cron.hourly' 'cron.monthly' 'cron.weekly' 'cron.d')
for c in "${crons[@]}"; do 
  cron-perm1-rem $c 
done

cron-perm2-rem
