#!/bin/bash

net-iface-chk() {
  echo -e "- Audit for ensuring wireless infteraces are disabled:"
  module_chk() {
    local l_mname="$1"
    local l_loadable=""
    local l_output=""
    local l_output2=""

    # Check how the module will be loaded
    l_loadable="$(modprobe -n -v "$l_mname")"
    if grep -Pq -- '^\h*install \/bin\/(true|false)' <<<"$l_loadable"; then
      l_output="$l_output\n\t- module: \"$l_mname\" is not loadable:  \"$l_loadable\""
    else
      l_output2="$l_output2\n\t- module: \"$l_mname\" is loadable:  \"$l_loadable\""
    fi

    # Check if the module is currently loaded
    if ! lsmod | grep "$l_mname" >/dev/null 2>&1; then
      l_output="$l_output\n\t- module: \"$l_mname\" is not loaded"
    else
      l_output2="$l_output2\n\t- module: \"$l_mname\" is loaded"
    fi

    # Check if the module is deny-listed
    if modprobe --showconfig | grep -Pq -- "^\h*blacklist\h+$l_mname\b"; then
      l_output="$l_output\n\t- module: \"$l_mname\" is deny listed in:  \"$(grep -Pl -- "^\h*blacklist\h+$l_mname\b" /etc/modprobe.d/*)\""
    else
      l_output2="$l_output2\n\t- module: \"$l_mname\" is not deny listed"
    fi

    # Output logs for module checks
    if [ -n "$l_output" ]; then
      echo -e "$l_output"
    fi
    if [ -n "$l_output2" ]; then
      echo -e "$l_output2"
    fi
  }

  # Main check for wireless network interface
  if [ -n "$(find /sys/class/net/*/ -type d -name wireless)" ]; then
    l_dname=$(for driverdir in $(find /sys/class/net/*/ -type d -name wireless | xargs -0 dirname); do basename "$(readlink -f "$driverdir"/device/driver/module)"; done | sort -u)
    for l_mname in $l_dname; do
      module_chk "$l_mname"
    done
  fi

  # Report audit results with title in square brackets
  if [ -z "$l_output2" ]; then
    echo -e "\t# Audit result [Module Loadability Check]: ** SUCCESS **"
    if [ -z "$l_output" ]; then
      echo -e "\t- System has no wireless NICs installed"
    else
      echo -e "$l_output"
    fi
  else
    echo -e "\t# Audit result [Module Loadability Check]: ** everythingisOK **\n\t- Reason(s) for audit failure:\n$l_output2"
    [ -n "$l_output" ] && echo -e "\t- Correctly set:\n$l_output"
  fi
}

net-iface-chk
