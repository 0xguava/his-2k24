#!/bin/bash 

ufw-installed-chk(){
  echo -e "- Audit for ufw installed check:"
  if dpkg-query -s ufw &>/dev/null; then
    echo -e "\t- Audit result: **PASS** [ufw is installed]"
  else
    echo -e "\t- Audit result: **FAIL** [ufw isn't installed]"
  fi
}

iptables-ins-chk(){
  echo -e "- Audit for ufw installed check:"
  if dpkg-query -s iptables-persistent &>/dev/null; then
    echo -e "\t- Audit result: **FAIL** [iptables is installed]"
  else
    echo -e "\t- Audit result: **PASS** [iptables isn't installed]"
  fi
}

enabled-chk(){
  local output_p=''
  local output_f=''

  if systemctl is-enabled ufw.service; then
    output_p="$output_p\n\t - ufw is enabled."
  else
    output_f="$output_f\n\t - ufw is enabled."
  fi

  if systemctl is-active ufw; then
    output_p="$output_p\n\t - ufw daemon is active."
  else
    output_f="$output_f\n\t - ufw daemon isn't active."
  fi

  if ufw status | grep 'inactive'; then
    output_f="$output_f\n\t - ufw isn't active."
  else
    output_p="$output_p\n\t - ufw is active."
  fi

  if [[ -z "$output_f" ]]; then
    echo -e "\t- Audit result: **PASS** [ufw enabled check]"
    echo -e "\t- Reason: $output_p"
  else
    echo -e "\t- Audit result: **FAIL** [ufw enabled check]"
    echo -e "\t- Reason: $output_f"
  fi
}

ufw_rules_chk() {
  echo -e "- UFW rules check:"
  local output_p=''
  local output_f=''
  local logvr=1

  # Check if UFW is enabled
  if ufw status | grep -q "Status: active"; then
    output_p="$output_p\n\t - UFW is enabled."
  else
    output_f="$output_f\n\t - UFW is not enabled."
    logvr=0
  fi

  # Check if rules are set correctly
  local rules=$(ufw status verbose)
  if echo "$rules" | grep -q "Anywhere on lo             ALLOW IN    Anywhere"; then
    output_p="$output_p\n\t - Rule 1: Allow incoming traffic on loopback interface is set correctly."
  else
    output_f="$output_f\n\t - Rule 1: Allow incoming traffic on loopback interface is not set correctly."
    logvr=0
  fi

  if echo "$rules" | grep -q "Anywhere                   DENY IN     127.0.0.0/8"; then
    output_p="$output_p\n\t - Rule 2: Deny incoming traffic from 127.0.0.0/8 is set correctly."
  else
    output_f="$output_f\n\t - Rule 2: Deny incoming traffic from 127.0.0.0/8 is not set correctly."
    logvr=0
  fi

  if echo "$rules" | grep -q "Anywhere (v6) on lo        ALLOW IN    Anywhere (v6)"; then
    output_p="$output_p\n\t - Rule 3: Allow incoming traffic on loopback interface (IPv6) is set correctly."
  else
    output_f="$output_f\n\t - Rule 3: Allow incoming traffic on loopback interface (IPv6) is not set correctly."
    logvr=0
  fi

  if echo "$rules" | grep -q "Anywhere (v6)              DENY IN     ::1"; then
    output_p="$output_p\n\t - Rule 4: Deny incoming traffic from ::1 (IPv6) is set correctly."
  else
    output_f="$output_f\n\t - Rule 4: Deny incoming traffic from ::1 (IPv6) is not set correctly."
    logvr=0
  fi

  if echo "$rules" | grep -q "Anywhere                   ALLOW OUT   Anywhere on lo"; then
    output_p="$output_p\n\t - Rule 5: Allow outgoing traffic on loopback interface is set correctly."
  else
    output_f="$output_f\n\t - Rule 5: Allow outgoing traffic on loopback interface is not set correctly."
    logvr=0
  fi

  if echo "$rules" | grep -q "Anywhere (v6)              ALLOW OUT   Anywhere (v6) on lo"; then
    output_p="$output_p\n\t - Rule 6: Allow outgoing traffic on loopback interface (IPv6) is set correctly."
  else
    output_f="$output_f\n\t - Rule 6: Allow outgoing traffic on loopback interface (IPv6) is not set correctly."
    logvr=0
  fi

  if [[ $logvr -eq 0 ]]; then
    echo -e "\t- Audit result: **FAIL** [UFW rules are not set correctly]"
    echo -e "\t- Reason: $output_f"
  else
    echo -e "\t- Audit result: **PASS** [UFW rules are set correctly]"
    echo -e "\t- Reason: $output_p"
  fi
}


iptables-ins-chk
ufw-installed-chk
enabled-chk 
ufw_rules_chk
