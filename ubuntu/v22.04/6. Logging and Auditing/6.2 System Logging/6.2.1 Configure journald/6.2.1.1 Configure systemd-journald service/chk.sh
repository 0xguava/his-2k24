#!/bin/bash

systemd_journald_chk() {
  echo -e "- Systemd-journald status check:"
  local l_output=""
  local l_output2=""

  # Verify systemd-journald is enabled
  echo -e "\t- Systemd-journald enabled check:"
  if systemctl is-enabled systemd-journald.service &>/dev/null; then
    local status=$(systemctl is-enabled systemd-journald.service)
    if [ "$status" = "static" ]; then
      l_output="$l_output\n\t- Audit result: **PASS** [Systemd-journald is enabled]"
    else
      l_output2="$l_output2\n\t- Audit result: **FAIL** [Systemd-journald is not enabled]"
      l_output2="$l_output2\n\t- Reason: Systemd-journald status is not static. Investigate why."
    fi
  else
    l_output2="$l_output2\n\t- Audit result: **FAIL** [Systemd-journald is not enabled]"
  fi

  # Verify systemd-journald is active
  echo -e "\t- Systemd-journald active check:"
  if systemctl is-active systemd-journald.service &>/dev/null; then
    local status=$(systemctl is-active systemd-journald.service)
    if [ "$status" = "active" ]; then
      l_output="$l_output\n\t- Audit result: **PASS** [Systemd-journald is active]"
    else
      l_output2="$l_output2\n\t- Audit result: **FAIL** [Systemd-journald is not active]"
    fi
  else
    l_output2="$l_output2\n\t- Audit result: **FAIL** [Systemd-journald is not active]"
  fi

  if [ -z "$l_output2" ]; then
    echo -e "\t- Audit result: **PASS** [Systemd-journald is properly configured]"
    echo -e "\t- Reason: $l_output"
  else
    echo -e "\t- Audit result: **FAIL** [Systemd-journald is not properly configured]"
    echo -e "\t- Reason: $l_output2"
    [ -n "$l_output" ] && echo -e "\n - Correctly configured:\n$l_output\n"
  fi
}

forward_to_syslog_chk() {

  echo -e "- ForwardToSyslog status check:"

  local l_output=""

  local l_output2=""

  local a_parlist=("ForwardToSyslog=yes")

  local l_systemd_config_file="/etc/systemd/journald.conf"


  config_file_parameter_chk() {

    unset A_out; declare -A A_out

    while read -r l_out; do

      if [ -n "$l_out" ]; then

        if [[ $l_out =~ ^\s*# ]]; then

          l_file="${l_out//# /}"

        else

          l_systemd_parameter="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"

          grep -Piq -- "^\h*$l_systemd_parameter_name\b" <<< "$l_systemd_parameter" && A_out+=(["$l_systemd_parameter"]="$l_file")

        fi

      fi

    done < <(/usr/bin/systemd-analyze cat-config "$l_systemd_config_file" | grep -Pio '^\h*([^#\n\r]+|#\h*\/[^#\n\r\h]+\.conf\b)')


    if (( ${#A_out[@]} > 0 )); then

      while IFS="=" read -r l_systemd_file_parameter_name l_systemd_file_parameter_value; do

        l_systemd_file_parameter_name="${l_systemd_file_parameter_name// /}"

        l_systemd_file_parameter_value="${l_systemd_file_parameter_value// /}"

        if ! grep -Piq "^\h*$l_systemd_parameter_value\b" <<< "$l_systemd_file_parameter_value"; then

          l_output="$l_output\n - \"$l_systemd_parameter_name\" is correctly set to \"$l_systemd_file_parameter_value\" in \"$(printf '%s' "${A_out[@]}")\"\n"

        else

          l_output2="$l_output2\n - \"$l_systemd_parameter_name\" is incorrectly set to \"$l_systemd_file_parameter_value\" in \"$(printf '%s' "${A_out[@]}")\"\n"

        fi

      done < <(grep -Pio -- "^\h*$l_systemd_parameter_name\h*=\h*\H+" "${A_out[@]}")

    else

      l_output="$l_output\n - \"$l_systemd_parameter_name\" is not set in an included file\n    ** Note: \"$l_systemd_parameter_name\" May be set in a file that's ignored by load procedure  **\n"

    fi

  }


  while IFS="=" read -r l_systemd_parameter_name l_systemd_parameter_value; do

    l_systemd_parameter_name="${l_systemd_parameter_name// /}"

    l_systemd_parameter_value="${l_systemd_parameter_value// /}"

    config_file_parameter_chk

  done < <(printf '%s\n' "${a_parlist[@]}")


  if [ -z "$l_output2" ]; then

    echo -e "\t- Audit result: **PASS** [ForwardToSyslog is not set to yes]"

    echo -e "\t- Reason: $l_output"

  else

    echo -e "\t- Audit result: **FAIL** [ForwardToSyslog is set to yes]"

    echo -e "\t- Reason: $l_output2"

    [ -n "$l_output" ] && echo -e "\n - Correctly set:\n$l_output\n"

  fi

}

storage_chk() {

  echo -e "- Storage status check:"

  local l_output=""

  local l_output2=""

  local a_parlist=("Storage=persistent")

  local l_systemd_config_file="/etc/systemd/journald.conf"


  config_file_parameter_chk() {

    unset A_out; declare -A A_out

    while read -r l_out; do

      if [ -n "$l_out" ]; then

        if [[ $l_out =~ ^\s*# ]]; then

          l_file="${l_out//# /}"

        else

          l_systemd_parameter="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"

          grep -Piq -- "^\h*$l_systemd_parameter_name\b" <<< "$l_systemd_parameter" && A_out+=(["$l_systemd_parameter"]="$l_file")

        fi

      fi

    done < <(/usr/bin/systemd-analyze cat-config "$l_systemd_config_file" | grep -Pio '^\h*([^#\n\r]+|#\h*\/[^#\n\r\h]+\.conf\b)')


    if (( ${#A_out[@]} > 0 )); then

      while IFS="=" read -r l_systemd_file_parameter_name l_systemd_file_parameter_value; do

        l_systemd_file_parameter_name="${l_systemd_file_parameter_name// /}"

        l_systemd_file_parameter_value="${l_systemd_file_parameter_value// /}"

        if grep -Piq "^\h*$l_systemd_parameter_value\b" <<< "$l_systemd_file_parameter_value"; then

          l_output="$l_output\n - \"$l_systemd_parameter_name\" is correctly set to \"$l_systemd_file_parameter_value\" in \"$(printf '%s' "${A_out[@]}")\"\n"

        else

          l_output2="$l_output2\n - \"$l_systemd_parameter_name\" is incorrectly set to \"$l_systemd_file_parameter_value\" in \"$(printf '%s' "${A_out[@]}")\" and should have a value matching: \"$l_systemd_parameter_value\"\n"

        fi

      done < <(grep -Pio -- "^\h*$l_systemd_parameter_name\h*=\h*\H+" "${A_out[@]}")

    else

      l_output2="$l_output2\n - \"$l_systemd_parameter_name\" is not set in an included file\n    ** Note: \"$l_systemd_parameter_name\" May be set in a file that's ignored by load procedure  **\n"

    fi

  }


  while IFS="=" read -r l_systemd_parameter_name l_systemd_parameter_value; do

    l_systemd_parameter_name="${l_systemd_parameter_name// /}"

    l_systemd_parameter_value="${l_systemd_parameter_value// /}"

    config_file_parameter_chk

  done < <(printf '%s\n' "${a_parlist[@]}")


  if [ -z "$l_output2" ]; then

    echo -e "\t- Audit result: **PASS** [Storage is set to persistent]"

    echo -e "\t- Reason: $l_output"

  else

    echo -e "\t- Audit result: **FAIL** [Storage is not set to persistent]"

    echo -e "\t- Reason: $l_output2"

    [ -n "$l_output" ] && echo -e "\n - Correctly set:\n$l_output\n"

  fi

}

compress_chk() {

  echo -e "- Compress status check:"

  local l_output=""

  local l_output2=""

  local a_parlist=("Compress=yes")

  local l_systemd_config_file="/etc/systemd/journald.conf"


  config_file_parameter_chk() {

    unset A_out; declare -A A_out

    while read -r l_out; do

      if [ -n "$l_out" ]; then

        if [[ $l_out =~ ^\s*# ]]; then

          l_file="${l_out//# /}"

        else

          l_systemd_parameter="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"

          grep -Piq -- "^\h*$l_systemd_parameter_name\b" <<< "$l_systemd_parameter" && A_out+=(["$l_systemd_parameter"]="$l_file")

        fi

      fi

    done < <(/usr/bin/systemd-analyze cat-config "$l_systemd_config_file" | grep -Pio '^\h*([^#\n\r]+|#\h*\/[^#\n\r\h]+\.conf\b)')


    if (( ${#A_out[@]} > 0 )); then

      while IFS="=" read -r l_systemd_file_parameter_name l_systemd_file_parameter_value; do

        l_systemd_file_parameter_name="${l_systemd_file_parameter_name// /}"

        l_systemd_file_parameter_value="${l_systemd_file_parameter_value// /}"

        if grep -Piq "^\h*$l_systemd_parameter_value\b" <<< "$l_systemd_file_parameter_value"; then

          l_output="$l_output\n - \"$l_systemd_parameter_name\" is correctly set to \"$l_systemd_file_parameter_value\" in \"$(printf '%s' "${A_out[@]}")\"\n"

        else

          l_output2="$l_output2\n - \"$l_systemd_parameter_name\" is incorrectly set to \"$l_systemd_file_parameter_value\" in \"$(printf '%s' "${A_out[@]}")\" and should have a value matching: \"$l_systemd_parameter_value\"\n"

        fi

      done < <(grep -Pio -- "^\h*$l_systemd_parameter_name\h*=\h*\H+" "${A_out[@]}")

    else

      l_output2="$l_output2\n - \"$l_systemd_parameter_name\" is not set in an included file\n    ** Note: \"$l_systemd_parameter_name\" May be set in a file that's ignored by load procedure  **\n"

    fi

  }


  while IFS="=" read -r l_systemd_parameter_name l_systemd_parameter_value; do

    l_systemd_parameter_name="${l_systemd_parameter_name// /}"

    l_systemd_parameter_value="${l_systemd_parameter_value// /}"

    config_file_parameter_chk

  done < <(printf '%s\n' "${a_parlist[@]}")


  if [ -z "$l_output2" ]; then

    echo -e "\t- Audit result: **PASS** [Compress is set to yes]"

    echo -e "\t- Reason: $l_output"

  else

    echo -e "\t- Audit result: **FAIL** [Compress is not set to yes]"

    echo -e "\t- Reason: $l_output2"

    [ -n "$l_output" ] && echo -e "\n - Correctly set:\n$l_output\n"

  fi

}



systemd_journald_chk
forward_to_syslog_chk
storage_chk
compress_chk
