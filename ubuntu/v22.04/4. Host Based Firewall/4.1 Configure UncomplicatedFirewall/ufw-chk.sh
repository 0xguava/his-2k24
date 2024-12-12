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

iptables-ins-chk
ufw-installed-chk
enabled-chk
