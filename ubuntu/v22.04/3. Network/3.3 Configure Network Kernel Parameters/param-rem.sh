#!/bin/bash

backup_and_apply_sysctl() {
  local param="$1"
  local value="$2"
  local file="/etc/sysctl.d/60-${param//./_}.conf"
  local output_p=""
  local output_f=""

  # Check if the configuration already exists
  if grep -q "^$param = $value" /etc/sysctl.conf /etc/sysctl.d/*.conf; then
    output_p+="\t- $param is already set to $value\n"
  else
    # Backup existing sysctl configuration files
    cp /etc/sysctl.conf /etc/sysctl.conf.bak
    cp -r /etc/sysctl.d /etc/sysctl.d.bak

    # Apply the configuration
    printf '%s\n' "$param = $value" >> "$file"
    sysctl -w "$param=$value" &>/dev/null && output_p+="\t- $param set to $value\n" || output_f+="\t- Failed to set $param to $value\n"
    sysctl -w net.ipv4.route.flush=1 &>/dev/null
  fi

  # Log the audit result
  if [[ -z "$output_f" ]]; then
    echo -e "\t- Audit result [$param]: **PASS**"
    echo -e "$output_p"
  else
    echo -e "\t- Audit result [$param]: **FAIL**"
    echo -e "$output_f"
  fi
}

remediate_ipv6() {
  local param="$1"
  local value="$2"
  local file="/etc/sysctl.d/60-${param//./_}.conf"
  local output_p=""
  local output_f=""

  # Check if IPv6 is enabled
  if [ -e /proc/sys/net/ipv6 ]; then
    # Check if the configuration already exists
    if grep -q "^$param = $value" /etc/sysctl.conf /etc/sysctl.d/*.conf; then
      output_p+="\t- $param is already set to $value\n"
    else
      # Backup existing sysctl configuration files
      cp /etc/sysctl.conf /etc/sysctl.conf.bak
      cp -r /etc/sysctl.d /etc/sysctl.d.bak

      # Apply the configuration
      printf '%s\n' "$param = $value" >> "$file"
      sysctl -w "$param=$value" &>/dev/null && output_p+="\t- $param set to $value\n" || output_f+="\t- Failed to set $param to $value\n"
      sysctl -w net.ipv6.route.flush=1 &>/dev/null
    fi
  else
    output_p+="\t- IPv6 is not enabled on this system, skipping $param\n"
  fi

  # Log the audit result
  if [[ -z "$output_f" ]]; then
    echo -e "\t- Audit result [$param]: **PASS**"
    echo -e "$output_p"
  else
    echo -e "\t- Audit result [$param]: **FAIL**"
    echo -e "$output_f"
  fi
}

backup_and_apply_sysctl "net.ipv4.ip_forward" 0
remediate_ipv6 "net.ipv6.conf.all.forwarding" 0
backup_and_apply_sysctl "net.ipv4.icmp_ignore_bogus_error_responses" 1
backup_and_apply_sysctl "net.ipv4.conf.all.send_redirects" 0
backup_and_apply_sysctl "net.ipv4.conf.default.send_redirects" 0
backup_and_apply_sysctl "net.ipv4.icmp_echo_ignore_broadcasts" 1
backup_and_apply_sysctl "net.ipv4.conf.all.accept_redirects" 0
backup_and_apply_sysctl "net.ipv4.conf.default.accept_redirects" 0
remediate_ipv6 "net.ipv6.conf.all.accept_redirects" 0
remediate_ipv6 "net.ipv6.conf.default.accept_redirects" 0
backup_and_apply_sysctl "net.ipv4.conf.all.secure_redirects" 0
backup_and_apply_sysctl "net.ipv4.conf.default.secure_redirects" 0
backup_and_apply_sysctl "net.ipv4.conf.all.rp_filter" 1
backup_and_apply_sysctl "net.ipv4.conf.default.rp_filter" 1
backup_and_apply_sysctl "net.ipv4.conf.all.accept_source_route" 0
backup_and_apply_sysctl "net.ipv4.conf.default.accept_source_route" 0
remediate_ipv6 "net.ipv6.conf.all.accept_source_route" 0
remediate_ipv6 "net.ipv6.conf.default.accept_source_route" 0
backup_and_apply_sysctl "net.ipv4.conf.all.log_martians" 1
backup_and_apply_sysctl "net.ipv4.conf.default.log_martians" 1
backup_and_apply_sysctl "net.ipv4.tcp_syncookies" 1
remediate_ipv6 "net.ipv6.conf.all.accept_ra" 0
remediate_ipv6 "net.ipv6.conf.default.accept_ra" 0

