#!/bin/bash

param-chk() {
# Initialize variables for output
l_output=""
l_output2=""

# List of kernel parameters to check
if [[ "$@" = 'forward' ]]; then
  a_parlist=("net.ipv4.ip_forward=0" "net.ipv6.conf.all.forwarding=0")
elif [[ "$@" = 'send' ]]; then
  a_parlist=("net.ipv4.conf.all.send_redirects=0" "net.ipv4.conf.default.send_redirects=0")
elif [[ "$@" = 'responses' ]]; then
  a_parlist=("net.ipv4.icmp_ignore_bogus_error_responses=1")
elif [[ "$@" = 'broadcasts' ]]; then
  a_parlist=("net.ipv4.icmp_echo_ignore_broadcasts=1")  
elif [[ "$@" = 'accept' ]]; then
  a_parlist=("net.ipv4.conf.all.accept_redirects=0" "net.ipv4.conf.default.accept_redirects=0"  "net.ipv6.conf.all.accept_redirects=0" "net.ipv6.conf.default.accept_redirects=0")
elif [[ "$@" = 'secure' ]]; then
  a_parlist=("net.ipv4.conf.all.secure_redirects=0" "net.ipv4.conf.default.secure_redirects=0")
elif [[ "$@" = 'rp' ]]; then
  a_parlist=("net.ipv4.conf.all.rp_filter=1" "net.ipv4.conf.default.rp_filter=1")
elif [[ "$@" = 'route' ]]; then
  a_parlist=("net.ipv4.conf.all.accept_source_route=0"  "net.ipv4.conf.default.accept_source_route=0" "net.ipv6.conf.all.accept_source_route=0"  "net.ipv6.conf.default.accept_source_route=0")
elif [[ "$@" = 'martians' ]]; then
  a_parlist=("net.ipv4.conf.all.log_martians=1" "net.ipv4.conf.default.log_martians=1")  a_parlist=("net.ipv4.conf.all.log_martians=1" "net.ipv4.conf.default.log_martians=1")  
elif [[ "$@" = 'tcp' ]]; then
  a_parlist=("net.ipv4.tcp_syncookies=1")
elif [[ "$@" = 'ra' ]]; then
  a_parlist=("net.ipv6.conf.all.accept_ra=0" "net.ipv6.conf.default.accept_ra=0")
fi

# UFW config file check
l_ufwscf="$([ -f /etc/default/ufw ] && awk -F= '/^\s*IPT_SYSCTL=/ {print $2}'  /etc/default/ufw)"

# Function to check kernel parameter settings
kernel_parameter_chk() {
  l_krp="$(sysctl "$l_kpname" | awk -F= '{print $2}' | xargs)" # Check running configuration

  # Check if the kernel parameter matches expected value
  if [ "$l_krp" = "$l_kpvalue" ]; then
    l_output="$l_output\n\t- \"$l_kpname\" is correctly set to \"$l_krp\" in the running configuration"
  else
    l_output2="$l_output2\n\t- \"$l_kpname\" is incorrectly set to \"$l_krp\" in the running configuration and should have a value of: \"$l_kpvalue\""
  fi

  unset A_out
  declare -A A_out # Check durable setting (files)
  
  # Check systemd config files for the parameter
  while read -r l_out; do
    if [ -n "$l_out" ]; then
      if [[ $l_out =~ ^\s*# ]]; then
        l_file="${l_out//# /}"
      else
        l_kpar="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"
        [ "$l_kpar" = "$l_kpname" ] && A_out+=(["$l_kpar"]="$l_file")
      fi
    fi
  done < <(/usr/lib/systemd/systemd-sysctl --cat-config | grep -Po  '^\h*([^#\n\r]+|#\h*\/[^#\n\r\h]+\.conf\b)')

  # If UFW is configured, check its config for the parameter
  if [ -n "$l_ufwscf" ]; then
    l_kpar="$(grep -Po "^\h*$l_kpname\b" "$l_ufwscf" | xargs)"
    l_kpar="${l_kpar//\//.}"
    [ "$l_kpar" = "$l_kpname" ] && A_out+=(["$l_kpar"]="$l_ufwscf")
  fi

  # If parameter found in config files, check against expected value
  if (( ${#A_out[@]} > 0 )); then
    while IFS="=" read -r l_fkpname l_fkpvalue; do
      l_fkpname="${l_fkpname// /}"
      l_fkpvalue="${l_fkpvalue// /}"
      if [ "$l_fkpvalue" = "$l_kpvalue" ]; then
        l_output="$l_output\n\t- \"$l_kpname\" is correctly set to \"$l_fkpvalue\" in \"$(printf '%s' "${A_out[@]}")\""
      else
        l_output2="$l_output2\n\t- \"$l_kpname\" is incorrectly set to \"$l_fkpvalue\" in \"$(printf '%s' "${A_out[@]}")\" and should have a value of: \"$l_kpvalue\""
      fi
    done < <(grep -Po -- "^\h*$l_kpname\h*=\h*\H+" "${A_out[@]}")
  else
    l_output2="$l_output2\n\t- \"$l_kpname\" is not set in an included file\n\t** Note: \"$l_kpname\" may be set in a file that's ignored by load procedure **"
  fi
}

# Loop through the parameters and perform checks
while IFS="=" read -r l_kpname l_kpvalue; do
  l_kpname="${l_kpname// /}"
  l_kpvalue="${l_kpvalue// /}"

  # Check for IPv6 availability
  if ! grep -Pqs '^\h*0\b' /sys/module/ipv6/parameters/disable && grep -q '^net.ipv6.' <<<  "$l_kpname"; then
    l_output="$l_output\n\t- IPv6 is disabled on the system, \"$l_kpname\" is not applicable"
  else
    kernel_parameter_chk
  fi
done < <(printf '%s\n' "${a_parlist[@]}")

# Final audit output
if [ -z "$l_output2" ]; then
  echo -e "\n- Audit Result [System Parameters]:\n  ** PASS **\n$l_output\n"
else
  echo -e "\n- Audit Result [System Parameters]:\n  ** FAIL **\n - Reason(s) for audit failure:\n$l_output2\n"
  [ -n "$l_output" ] && echo -e "\n- Correctly set:\n$l_output\n"
fi
}

params=('forward' 'send' 'responses' 'broadcasts' 'accept' 'secure' 'rp' 'route' 'martians' 'tcp' 'ra')
for p in "${params[@]}"; do
  param-chk $p 
done
