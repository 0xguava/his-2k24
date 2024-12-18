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

firewall_rule_chk() {

  echo -e "- Firewall rule check for open ports:"

  local output_p=''

  local output_f=''

  local logvr=1


  # Get UFW open ports

  local a_ufwout=()

  while read -r l_ufwport; do

    [ -n "$l_ufwport" ] && a_ufwout+=("$l_ufwport")

  done < <(ufw status verbose | grep -Po '^\h*\d+\b' | sort -u)


  # Get open ports

  local a_openports=()

  while read -r l_openport; do

    [ -n "$l_openport" ] && a_openports+=("$l_openport")

  done < <(ss -tuln | awk '($5!~/%lo:/ && $5!~/127.0.0.1:/ &&  $5!~/\[?::1\]?:/) {split($5, a, ":"); print a[2]}' | sort -u)


  # Find ports without UFW rules

  local a_diff=($(printf '%s\n' "${a_openports[@]}" "${a_ufwout[@]}" "${a_ufwout[@]}" | sort | uniq -u))


  if [[ -n "${a_diff[*]}" ]]; then

    output_f="$output_f\n\t - The following port(s) don't have a rule in UFW: $(printf '%s\n' "${a_diff[*]}")"

    logvr=0

  else

    output_p="$output_p\n\t - All open ports have a rule in UFW"

  fi


  if [[ $logvr -eq 0 ]]; then

    echo -e "\t- Audit result: **FAIL** [Firewall rule is not set correctly]"

    echo -e "\t- Reason: $output_f"

  else

    echo -e "\t- Audit result: **PASS** [Firewall rule is set correctly]"

    echo -e "\t- Reason: $output_p"

  fi

}

default_policy_chk() {

  echo -e "- Default policy check for incoming, outgoing, and routed directions:"

  local output_p=''

  local output_f=''

  local logvr=1


  # Get default policy

  local default_policy=$(ufw status verbose | grep Default:)


  # Check incoming policy

  if echo "$default_policy" | grep -q "deny (incoming)"; then

    output_p="$output_p\n\t - Incoming policy is set to deny"

  elif echo "$default_policy" | grep -q "reject (incoming)"; then

    output_p="$output_p\n\t - Incoming policy is set to reject"

  else

    output_f="$output_f\n\t - Incoming policy is not set to deny or reject"

    logvr=0

  fi


  # Check outgoing policy

  if echo "$default_policy" | grep -q "deny (outgoing)"; then

    output_p="$output_p\n\t - Outgoing policy is set to deny"

  elif echo "$default_policy" | grep -q "reject (outgoing)"; then

    output_p="$output_p\n\t - Outgoing policy is set to reject"

  else

    output_f="$output_f\n\t - Outgoing policy is not set to deny or reject"

    logvr=0

  fi


  # Check routed policy

  if echo "$default_policy" | grep -q "disabled (routed)"; then

    output_p="$output_p\n\t - Routed policy is set to disabled"

  else

    output_f="$output_f\n\t - Routed policy is not set to disabled"

    logvr=0

  fi


  if [[ $logvr -eq 0 ]]; then

    echo -e "\t- Audit result: **FAIL** [Default policy is not set correctly]"

    echo -e "\t- Reason: $output_f"

  else

    echo -e "\t- Audit result: **PASS** [Default policy is set correctly]"

    echo -e "\t- Reason: $output_p"

  fi

}

iptables-ins-chk
ufw-installed-chk
enabled-chk 
ufw_rules_chk
firewall_rule_chear
default_policy_chk

