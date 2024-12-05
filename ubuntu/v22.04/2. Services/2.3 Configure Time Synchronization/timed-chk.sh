#!/bin/bash

daemon-chk(){
  l_output="" l_output2=""
  service_not_enabled_chk() {
    l_out2=""
    if systemctl is-enabled "$l_service_name" 2>/dev/null | grep -q 'enabled'; then
      l_out2="$l_out2\n\t - Daemon: \"$l_service_name\" is enabled on the system"
    fi
    if systemctl is-active "$l_service_name" 2>/dev/null | grep -q '^active'; then
      l_out2="$l_out2\n\t - Daemon: \"$l_service_name\" is active on the system"
    fi
  }
  l_service_name="systemd-timesyncd.service" # Check systemd-timesyncd daemon
  service_not_enabled_chk
  if [ -n "$l_out2" ]; then
    l_timesyncd="y"
    l_out_tsd="$l_out2"
  else
    l_timesyncd="n"
    l_out_tsd="\n\t - Daemon: \"$l_service_name\" is not enabled and not active on the system"
  fi
  l_service_name="chrony.service" # Check chrony
  service_not_enabled_chk
  if [ -n "$l_out2" ]; then
    l_chrony="y"
    l_out_chrony="$l_out2"
  else
    l_chrony="n"
    l_out_chrony="\n\t - Daemon: \"$l_service_name\" is not enabled and not active on the system"
  fi
  l_status="$l_timesyncd$l_chrony"
  case "$l_status" in
  yy)
    l_output2="\n\t - More than one time sync daemon is in use on the system$l_out_tsd$l_out_chrony"
    ;;
  nn)
    l_output2="\n\t - No time sync daemon is in use on the system$l_out_tsd$l_out_chrony"
    ;;
  yn | ny)
    l_output="\n\t - Only one time sync daemon is in use on the system$l_out_tsd$l_out_chrony"
    ;;
  *)
    l_output2="\n\t - Unable to determine time sync daemon(s) status"
    ;;
  esac
  echo -e "- Audit for time sync daemon:"
  if [ -z "$l_output2" ]; then
    echo -e "\t# Audit Result: **PASS** [time sync daemon] $l_output"
  else
    echo -e "\t# Audit Result: **FAIL** [time sync daemon]\n\t - * Reasons for audit failure :$l_output2"
  fi
}

systemd-chk() {
  l_output="" l_output2=""
  a_parlist=("NTP=[^#\n\r]+" "FallbackNTP=[^#\n\r]+")
  l_systemd_config_file="/etc/systemd/timesyncd.conf" # Main systemd configuration file
  config_file_parameter_chk() {
    unset A_out
    declare -A A_out # Check config file(s) setting
    while read -r l_out; do
      if [ -n "$l_out" ]; then
        if [[ $l_out =~ ^\s*# ]]; then
          l_file="${l_out//# /}"
        else
          l_systemd_parameter="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"
          grep -Piq -- "^\h*$l_systemd_parameter_name\b" <<< "$l_systemd_parameter" &&
            A_out+=(["$l_systemd_parameter"]="$l_file")
        fi
      fi
    done < <(/usr/bin/systemd-analyze cat-config "$l_systemd_config_file" | grep -Pio '^\h*([^#\n\r]+|#\h*\/[^#\n\r\h]+\.conf\b)')
    if ((${#A_out[@]} > 0)); then # Assess output from files and generate output
      while IFS="=" read -r l_systemd_file_parameter_name l_systemd_file_parameter_value; do
        l_systemd_file_parameter_name="${l_systemd_file_parameter_name// /}"
        l_systemd_file_parameter_value="${l_systemd_file_parameter_value// /}"
        if grep -Piq "^\h*$l_systemd_parameter_value\b" <<< "$l_systemd_file_parameter_value"; then
          l_output="$l_output\n\t - \"$l_systemd_parameter_name\" is correctly set to \"$l_systemd_file_parameter_value\" in \"$(printf '%s' "${A_out[@]}")\""
        else
          l_output2="$l_output2\n\t - \"$l_systemd_parameter_name\" is incorrectly set to \"$l_systemd_file_parameter_value\" in \"$(printf '%s' "${A_out[@]}")\" and should have a value matching: \"$l_systemd_parameter_value\""
        fi
      done < <(grep -Pio "^\h*$l_systemd_parameter_name\h*=\h*\H+" "${A_out[@]}")
    else
      l_output2="$l_output2\n\t - \"$l_systemd_parameter_name\" is not set in an included file\n\t ** Note: \"$l_systemd_parameter_name\" May be set in a file that's ignored by load procedure**"
    fi
  }
  while IFS="=" read -r l_systemd_parameter_name l_systemd_parameter_value; do # Assess and check parameters
    l_systemd_parameter_name="${l_systemd_parameter_name// /}"
    l_systemd_parameter_value="${l_systemd_parameter_value// /}"
    config_file_parameter_chk
  done < <(printf '%s\n' "${a_parlist[@]}")
  echo -e "\n- systemd-timesyncd configuration check:"
  if [ -z "$l_output2" ]; then # Provide output from checks
    echo -e "\t# Audit Result: **PASS** [systemd-timesyncd is configured with timeserver]$l_output"
  else
    echo -e "\t# Audit Result: **FAIL** [systemd-timesyncd isn't configured with timeserver]\n\t- Reason(s) for audit failure:$l_output2"
    [ -n "$l_output" ] && echo -e "- Correctly set:$l_output"
  fi
}

chrony-pool-chk(){
  l_output=""
  l_output2=""
  a_parlist=("^\h*(server|pool)\h+\H+")
  l_chrony_config_dir="/etc/chrony" # Chrony configuration directory
  config_file_parameter_chk() {
    unset A_out
    declare -A A_out
    while read -r l_out; do
      if [ -n "$l_out" ]; then
        if [[ $l_out =~ ^\s*# ]]; then
          l_file="${l_out//# /}"
        else
          l_chrony_parameter="$(awk -F= '{print $1}' <<< "$l_out" |xargs)"
          A_out+=(["$l_chrony_parameter"]="$l_file")
        fi
      fi
    done < <(find "$l_chrony_config_dir" -name '*.conf' -exec systemd-analyze cat-config {} + | grep -Pio '^\h*([^#\n\r]+|#\h*\/[^#\n\r\h]+\.conf\b)')
    if ((${#A_out[@]} > 0)); then
      for l_chrony_parameter in "${!A_out[@]}"; do
        l_file="${A_out[$l_chrony_parameter]}"
        l_output="$l_output\n\t - \"$l_chrony_parameter\" is set in \"$l_file\""
      done
    else
      l_output2="$l_output2\n\t - No 'server' or 'pool' settings found in Chrony configuration files"
    fi
  }
  for l_chrony_parameter_regex in "${a_parlist[@]}"; do
    config_file_parameter_chk
  done
  echo -e "\n- chrony configuration check:"
  if [ -z "$l_output2" ]; then
    echo -e "\t# Audit Result: **PASS** [chrony is configured with timeserver]$l_output"
  else
    echo -e "\t# Audit Result: **FAIL** [chrony isn't configured with timeserver]\n\t- Reason(s) for audit failure:$l_output2"
    [ -n "$l_output" ] && echo -e "- Correctly set:$l_output"
  fi
}

chrony-run-chk(){
  echo -e "\n- Checking if chronyd is running as the _chrony user"
  # Run the audit command
  INVALID_USERS=$(ps -ef | awk '(/[c]hronyd/ && $1!="_chrony") { print $1 }')

  if [ -z "$INVALID_USERS" ]; then
    echo -e "\t# Audit Result: **PASS** [chronyd is runnig as _chrony user]"
  else
    echo -e "\t# Audit Result: **FAIL** [chronyd isn't runnig as _chrony user]"
    echo "$INVALID_USERS"
  fi
}

daemon-chk
systemd-chk
chrony-pool-chk
chrony-run-chk
