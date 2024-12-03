#!/bin/bash

service-chk() {
  local pkg_output=''
  local output_p=''
  local output_f=''
  local logvr=1
  local pkg_name=$(echo $@ | cut -d\. -f1)

  if [[ "$pkg_name" = "dovecot" ]]; then
    dpkg-query -s dovecot-imapd &>/dev/null && pkg_output="$pkg_output\t- dovecot-imapd is installed." || pkg_output="$pkg_output\t- dovecot-imapd isn't installed."
    dpkg-query -s dovecot-pop3d &>/dev/null && pkg_output="$pkg_output\n\t- dovecot-pop3d is installed." || pkg_output="$pkg_output\n\t- dovecot-pop3d isn't installed."
  elif [[ "$pkg_name" = "nfs-server" ]]; then
    dpkg-query -s nfs-kernel-server &>/dev/null && pkg_output="$pkg_output\t- nfs-kernel-server is installed." || pkg_output="$pkg_output\t- nfs-kernel-server isn't installed."
  elif [[ "$pkg_name" = "smbd" ]]; then
    dpkg-query -s samba &>/dev/null && pkg_output="$pkg_output\t- samba is installed." || pkg_output="$pkg_output\t- samba isn't installed."
  elif [[ "$pkg_name" = "apache2" ]]; then
    dpkg-query -s apache2 &>/dev/null && pkg_output="$pkg_output\t- apache2 is installed." || pkg_output="$pkg_output\t- apache2 isn't installed."
    dpkg-query -s nginx &>/dev/null && pkg_output="$pkg_output\n\t- nginx is installed." || pkg_output="$pkg_output\n\t- nginx isn't installed."
  else 
    dpkg-query -s "$pkg_name" &>/dev/null && pkg_output="$pkg_output\t- $pkg_name is installed." || pkg_output="$pkg_output\t- $pkg_name isn't installed."
  fi

  if systemctl is-enabled "$@" 2>/dev/null | grep -q 'enabled'; then
    output_f="$output_f\n\t - $@ is enabled."
    logvr=0
  else
    output_p="$output_p\n\t - $@ is NOT enabled."
  fi

  if systemctl is-active "$@" 2>/dev/null | grep -q '^active'; then
    output_f="$output_f\n\t - $@ is active."
    logvr=0
  else
    output_p="$output_p\n\t - $@ is NOT active."
  fi

  echo -e "- Audit for $pkg_name:"
  echo -e "$pkg_output"
  if [[ $logvr -eq 0 ]]; then
    echo -e "\t# Audit result: **FAIL** [$@]"
    echo -e "\t- Reason: $output_f"
  else
    echo -e "\t# Audit result: **PASS** [$@]"
    echo -e "\t- Reason: $output_p"
  fi
}

mta-chk(){
  l_output=""
  l_output2=""
  a_port_list=("25" "465" "587")
  # Check if inet_interfaces is not set to all
  if [ "$(postconf -n inet_interfaces)" != "inet_interfaces = all" ]; then
    for l_port_number in "${a_port_list[@]}"; do
      if ss -plntu | grep -P -- ':'"$l_port_number"'\b' | grep -Pvq '\h+(127\.0\.0\.1|\[?::1\]?):'"$l_port_number"'\b'; then
        l_output2="$l_output2\n\t - Port \"$l_port_number\" is listening on a non-loopback network interface"
      else
        l_output="$l_output\n\t - Port \"$l_port_number\" is not listening on a non-loopback network interface"
      fi
    done
  else
    l_output2="$l_output2\n\t - Postfix is bound to all interfaces"
  fi
  unset a_port_list
  # Provide output from checks
  echo -e "- Audit for mail transfer agent:"
  if [ -z "$l_output2" ]; then
    echo -e "\t# Audit Result: **PASS** $l_output"
  else
    # If errooutput (l_output2) is not empty, we fail. Also output anything that's correctly configured
    echo -e "\t# Audit Result: **FAIL**\n\t- Reason(s) for audit failure:$l_output2"
    [ -n "$l_output" ] && echo -e "\n- Correctly set:$l_output"
  fi
}


services=('autofs.service' 'avahi-daemon.socket avahi-daemon.service' 'isc-dhcp-server.service isc-dhcp-server6.service' 'bind9.service' 'dnsmasq.service' 'vsftpd.service' 'slapd.service' 'dovecot.socket dovecot.service' 'nfs-server.service' 'ypserv.service' 'cups.socket cups.service' 'rpcbind.socket rpcbind.service' 'rsync.service' 'smbd.service' 'snmpd.service' 'tftpd-hpa.service' 'squid.service' 'apache2.socket apache2.service nginx.service' 'xinetd.service')

for s in "${services[@]}"; do 
  service-chk $s 
done

mta-chk
