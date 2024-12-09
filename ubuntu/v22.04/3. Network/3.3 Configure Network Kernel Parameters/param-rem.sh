#!/bin/bash

ip-forward-rem() {
  local output_p=""
  local output_f=""

  # Check if IPv4 forwarding configuration already exists
  if grep -q "^net.ipv4.ip_forward = 0" /etc/sysctl.conf /etc/sysctl.d/*.conf; then
    output_p+="\t- IPv4 forwarding is already disabled\n"
  else
    # Backup existing sysctl configuration files
    cp /etc/sysctl.conf /etc/sysctl.conf.bak
    cp -r /etc/sysctl.d /etc/sysctl.d.bak

    echo "net.ipv4.ip_forward = 0" >> /etc/sysctl.d/60netipv4_sysctl.conf
    sysctl -w net.ipv4.ip_forward=0 &>/dev/null && output_p+="\t- IPv4 forwarding disabled\n" || output_f+="\t- Failed to disable IPv4 forwarding\n"
    sysctl -w net.ipv4.route.flush=1 &>/dev/null
  fi

  # Check if IPv6 is enabled and its forwarding configuration
  if [ -e /proc/sys/net/ipv6 ]; then
    if grep -q "^net.ipv6.conf.all.forwarding = 0" /etc/sysctl.conf /etc/sysctl.d/*.conf; then
      output_p+="\t- IPv6 forwarding is already disabled\n"
    else
      echo "net.ipv6.conf.all.forwarding = 0" >> /etc/sysctl.d/60netipv6_sysctl.conf
      sysctl -w net.ipv6.conf.all.forwarding=0 &>/dev/null && output_p+="\t- IPv6 forwarding disabled\n" || output_f+="\t- Failed to disable IPv6 forwarding\n"
      sysctl -w net.ipv6.route.flush=1 &>/dev/null
    fi
  else
    output_p+="\t- IPv6 is not enabled on this system\n"
  fi

  # Log the audit result
  if [[ -z "$output_f" ]]; then
    echo -e "\t- Audit result [IP Forwarding Remediation]: **PASS**"
    echo -e "$output_p"
  else
    echo -e "\t- Audit result [IP Forwarding Remediation]: **FAIL**"
    echo -e "$output_f"
  fi
}

ip-forward-rem
