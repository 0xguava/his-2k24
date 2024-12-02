#!/bin/bash

lr-pt-ch() {
  l_output="" l_output2=""
  a_parlist=($@)
  l_ufwscf="$([ -f /etc/default/ufw ] && awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw)"
  kernel_parameter_chk() {
    l_krp="$(sysctl "$l_kpname" | awk -F= '{print $2}' | xargs)" # Check running configuration
    if [ "$l_krp" = "$l_kpvalue" ]; then
      l_output="$l_output\n\t - \"$l_kpname\" is correctly set to \"$l_krp\" in the running configuration"
    else
      l_output2="$l_output2\n\t - \"$l_kpname\" is incorrectly set to \"$l_krp\" in the running configuration and should have a value of: \"$l_kpvalue\""
    fi
    unset A_out
    declare -A A_out # Check durable setting (files)
    while read -r l_out; do
      if [ -n "$l_out" ]; then
        if [[ $l_out =~ ^\s*# ]]; then
          l_file="${l_out//# /}"
        else
          l_kpar="$(awk -F= '{print $1}' <<<"$l_out" | xargs)"
          [ "$l_kpar" = "$l_kpname" ] && A_out+=(["$l_kpar"]="$l_file")
        fi
      fi
    done < <(/usr/lib/systemd/systemd-sysctl --cat-config | grep -Po '^\h*([^#\n\r]+|#\h*\/[^#\n\r\h]+\.conf\b)')
    if [ -n "$l_ufwscf" ]; then # Account for systems with UFW (Not covered by systemd-sysctl -cat-config)
      l_kpar="$(grep -Po "^\h*$l_kpname\b" "$l_ufwscf" | xargs)"
      l_kpar="${l_kpar//\//.}"
      [ "$l_kpar" = "$l_kpname" ] && A_out+=(["$l_kpar"]="$l_ufwscf")
    fi
    if ((${#A_out[@]} > 0)); then # Assess output from files and generate output
      while IFS="=" read -r l_fkpname l_fkpvalue; do
        l_fkpname="${l_fkpname// /}"
        l_fkpvalue="${l_fkpvalue// /}"
        if [ "$l_fkpvalue" = "$l_kpvalue" ]; then
          l_output="$l_output\n\t - \"$l_kpname\" is correctly set to \"$l_fkpvalue\" in\"$(printf '%s' "${A_out[@]}")\""
        else
          l_output2="$l_output2\n\t - \"$l_kpname\" is incorrectly set to \"$l_fkpvalue\" in\"$(printf '%s' "${A_out[@]}")\" and should have a value of: \"$l_kpvalue\""
        fi
      done < <(grep -Po -- "^\h*$l_kpname\h*=\h*\H+" "${A_out[@]}")
    else
      l_output2="$l_output2\n\t - \"$l_kpname\" is not set in an included file\n\t   ** Note:\"$l_kpname\" May be set in a file that's ignored by load procedure **"
    fi
  }
  while IFS="=" read -r l_kpname l_kpvalue; do # Assess and check parameters
    l_kpname="${l_kpname// /}"
    l_kpvalue="${l_kpvalue// /}"
    if ! grep -Pqs '^\h*0\b' /sys/module/ipv6/parameters/disable && grep -q '^net.ipv6.' <<<"$l_kpname"; then
      l_output="$l_output\n\t - IPv6 is disabled on the system, \"$l_kpname\" is not applicable"
    else
      kernel_parameter_chk
    fi
  done < <(printf '%s\n' "${a_parlist[@]}")
  echo -e "\n- Audit for Process Hardening:"
  if [ -z "$l_output2" ]; then # Provide output from checks
    echo -e "\t- Audit Result: **PASS** [ "$@" ]$l_output"
  else
    echo -e "\t- Audit Result: **FAIL** [ "$@" ]\n\t - Reason(s) for audit failure:$l_output2"
    [ -n "$l_output" ] && echo -e "\t- Correctly set:$l_output"
  fi
}

installed-chk(){
  local logvr=1

  echo -e "\n- Audit for \"$@ installed check\":"
  if [[ -n "$(dpkg-query -s $@ 2> /dev/null)" ]]; then
    logvr=0
  fi

  if [[ $logvr -eq 0 ]]; then
    echo -e "\t- Audit result: **FAIL** [$@ shouldn't be installed]"
  else
    echo -e "\t- Audit result: **PASS** [$@ is not installed]"
  fi
}

opts=('kernel.randomize_va_space=2' 'kernel.yama.ptrace_scope=1' 'fs.suid_dumpable=0')
for opt in "${opts[@]}"; do 
  lr-pt-ch "$opt"
done

pkgs=('prelink' 'apport')
for pkg in "${pkgs[@]}";do 
  installed-chk "$pkg"
done
