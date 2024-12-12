#!/bin/bash

aide_installation_chk() {
  echo -e "- AIDE installation check:"
  if dpkg-query -s aide &>/dev/null; then
    echo -e "\t- Audit result: **PASS** [AIDE is installed]"
  else
    echo -e "\t- Audit result: **FAIL** [AIDE isn't installed]"
  fi
}

aide_common_installation_chk() {
  echo -e "- AIDE-common installation check:"
  if dpkg-query -s aide-common &>/dev/null; then
    echo -e "\t- Audit result: **PASS** [AIDE-common is installed]"
  else
    echo -e "\t- Audit result: **FAIL** [AIDE-common isn't installed]"
  fi
}

aide_cron_job_chk() {

  echo -e "- AIDE cron job check:"

  if grep -Prs '^([^#\n\r]+\h+)?(\/usr\/s?bin\/|^\h*)aide(\.wrapper)?\h+(-(check|update)|([^#\n\r]+\h+)?\$AIDEARGS)\b' /etc/cron.* /etc/crontab /var/spool/cron/ &>/dev/null; then

    echo -e "\t- Audit result: **PASS** [AIDE cron job is scheduled]"

  else

    echo -e "\t- Audit result: **FAIL** [AIDE cron job isn't scheduled]"

  fi

}

aide_service_timer_chk() {

  echo -e "- AIDE check service and timer check:"

  local output_p=''

  local output_f=''

  local logvr=1


  if systemctl is-enabled aidecheck.service &>/dev/null; then

    output_p="$output_p\n\t - AIDE check service is enabled."

  else

    output_f="$output_f\n\t - AIDE check service isn't enabled."

    logvr=0

  fi


  if systemctl is-enabled aidecheck.timer &>/dev/null; then

    output_p="$output_p\n\t - AIDE check timer is enabled."

  else

    output_f="$output_f\n\t - AIDE check timer isn't enabled."

    logvr=0

  fi


  if systemctl status aidecheck.timer | grep -q "active (running)"; then

    output_p="$output_p\n\t - AIDE check timer is running."

  else

    output_f="$output_f\n\t - AIDE check timer isn't running."

    logvr=0

  fi


  if [[ $logvr -eq 0 ]]; then

    echo -e "\t- Audit result: **FAIL** [AIDE check service and timer aren't configured properly]"

    echo -e "\t- Reason: $output_f"

  else

    echo -e "\t- Audit result: **PASS** [AIDE check service and timer are configured properly]"

    echo -e "\t- Reason: $output_p"

  fi

}

aide_config_chk() {

  echo -e "- AIDE configuration check:"

  local l_output=""

  local l_output2=""

  local a_items=("p" "i" "n" "u" "g" "s" "b" "acl" "xattrs" "sha512")

  local a_parlist=("/sbin/auditctl" "/sbin/auditd" "/sbin/ausearch" "/sbin/aureport" "/sbin/autrace" "/sbin/augenrules")

  local A_out=()


  if [ -f "/etc/aide/aide.conf" ]; then

    l_config_file="/etc/aide/aide.conf"

  elif [ -f "/etc/aide.conf" ]; then

    l_config_file="/etc/aide.conf"

  else

    echo -e "\t- Audit result: **FAIL** [AIDE configuration file not found]"

    echo -e "\t- Reason: AIDE configuration file not found. Please verify AIDE is installed on the system"

    return

  fi


  while IFS= read -r l_out; do

    if [ -n "$l_out" ]; then

      if [[ $l_out =~ ^\s*# ]]; then

        l_file="${l_out//# /}"

      else

        l_parameter="$l_out"

        A_out+=("$l_parameter" "$l_file")

      fi

    fi

  done < <(/usr/bin/systemd-analyze cat-config "$l_config_file" | grep -Pio '^\h*([^#\n\r]+|#\h*\/[^#\n\r\h]+\.conf\b)')


  for l_parameter_name in "${a_parlist[@]}"; do

    if [ -f "$l_parameter_name" ]; then

      local l_out=""

      local l_out2=""

      for l_string in "${A_out[@]}"; do

        l_file_parameter="$(grep -Po -- "^\h*$l_parameter_name\b.*$" <<< "$l_string")"

        if [ -n "$l_file_parameter" ]; then

          l_file="$(printf '%s' "${A_out[$l_file_parameter]}")"

          l_out="$l_out\n  - Exists as: \"$l_file_parameter\n   - in the configuration file:  \"$l_file\""

          for l_var in "${a_items[@]}"; do

            if ! grep -Pq -- "\b$l_var\b" <<< "$l_file_parameter"; then

              l_out2="$l_out2\n  - Option: \"$l_var\" is missing from: \"$l_file_parameter\"  in: \"$l_file\""

            fi

          done

        fi

      done

      [ -n "$l_out" ] && l_output="$l_output\n - Parameter: \"$l_parameter_name\":$l_out"

      [ -z "$l_out2" ] && l_output="$l_output\n    - and includes \"$(printf '%s+' "${a_items[@]}")\""

      [ -n "$l_out2" ] && l_output2="$l_output2\n - Parameter: \"$l_parameter_name\":$l_out2"

      [[ -z "$l_out" && -z "$l_out2" ]] && l_output2="$l_output2\n - Parameter: \"$l_parameter_name\" is not configured"

    else

      l_output="$l_output\n - ** Warning **\n   Audit tool file: \"$l_parameter_name\" does not exist\n   Please verify auditd is installed"

    fi

  done


  if [ -z "$l_output2" ]; then

    echo -e "\t- Audit result: **PASS** [AIDE is properly configured]"

    echo -e "\t- Reason: $l_output"

  else

    echo -e "\t- Audit result: **FAIL** [AIDE is not properly configured]"

    echo -e "\t- Reason: $l_output2"

    [ -n "$l_output" ] && echo -e "\n - Correctly configured:\n$l_output\n"

  fi

}


aide_installation_chk
aide_common_installation_chk
aide_cron_job_chk
aide_service_timer_chk
aide_config_chk
