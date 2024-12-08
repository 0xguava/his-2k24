#!/bin/bash

net-iface-rem() {
  local l_mname="$1"
  local output_p=""
  local output_f=""

  # Check if module can be set to un-loadable and fix it
  if ! modprobe -n -v "$l_mname" | grep -P -- '^\h*install  \/bin\/(true|false)'; then
    output_p="$output_p\n\t- Setting module: \"$l_mname\" to be un-loadable"
    echo -e "install $l_mname /bin/false" >> /etc/modprobe.d/"$l_mname".conf
  else
    output_f="$output_f\n\t- Module: \"$l_mname\" is already set to un-loadable"
  fi

  # Check if module is loaded and unload it if necessary
  if lsmod | grep "$l_mname" > /dev/null 2>&1; then
    output_p="$output_p\n\t- Unloading module: \"$l_mname\""
    modprobe -r "$l_mname"
  else
    output_f="$output_f\n\t- Module: \"$l_mname\" is not loaded"
  fi

  # Check if module is deny-listed and add it if not
  if ! grep -Pq -- "^\h*blacklist\h+$l_mname\b" /etc/modprobe.d/*; then
    output_p="$output_p\n\t- Deny listing module: \"$l_mname\""
    echo -e "blacklist $l_mname" >> /etc/modprobe.d/"$l_mname".conf
  else
    output_f="$output_f\n\t- Module: \"$l_mname\" is already deny-listed"
  fi

  # Report remediation results
  if [ -z "$output_f" ]; then
    echo -e "\n- Remediation result [Module Fix]: ** SUCCESS **"
    echo -e "$output_p"
  else
    echo -e "\n- Remediation result [Module Fix]: ** everythingisOK **"
    echo -e "\n- Reason(s) for remediation failure:\n$output_f"
  fi
}

bluetooth_remediation() {
  local output_p=""
  local output_f=""

  # Check if the bluetooth.service is enabled and active
  if systemctl is-active --quiet bluetooth.service; then
    output_p="$output_p\n\t- Stopping bluetooth.service"
    systemctl stop bluetooth.service
  else
    output_f="$output_f\n\t- bluetooth.service is not active"
  fi

  if systemctl is-enabled --quiet bluetooth.service; then
    output_p="$output_p\n\t- Masking bluetooth.service"
    systemctl mask bluetooth.service
  else
    output_f="$output_f\n\t- bluetooth.service is already masked"
  fi

  # Report remediation results
  if [ -z "$output_f" ]; then
    echo -e "\n- Remediation result [Bluetooth Service Fix]: ** SUCCESS **"
    echo -e "$output_p"
  else
    echo -e "\n- Remediation result [Bluetooth Service Fix]: ** everythingisOK **"
    echo -e "\n- Reason(s) for remediation failure:\n$output_f"
  fi
}

# Remediation begin for net-ifaces 
if [ -n "$(find /sys/class/net/*/ -type d -name wireless)" ]; then
  l_dname=$(for driverdir in $(find /sys/class/net/*/ -type d -name wireless | xargs -0 dirname); do basename "$(readlink -f  "$driverdir"/device/driver/module)";done | sort -u)
  for l_mname in $l_dname; do
    net-iface-rem "$l_mname"
  done
fi

bluetooth_remediation

