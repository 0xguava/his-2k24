#!/bin/bash

module-rem() {
  local l_mname="$@"
  local output_p=""
  local output_f=""

  # Function to back up a file if it exists
  backup_file() {
    local file="$1"
    if [ -e "$file" ]; then
      cp "$file" "$file.bak"
      echo -e "\t- Backup of \"$file\" created: \"$file.bak\""
    fi
  }

  # Check if the module is available in the running kernel
  if lsmod | grep -q "$l_mname"; then
    # Remediation - Create file with install dccp /bin/false
    output_p="$output_p\n\t- Module \"$l_mname\" is available in the running kernel"
    backup_file "/etc/modprobe.d/$l_mname.conf"
    echo -e "install $l_mname /bin/false" > /etc/modprobe.d/"$l_mname".conf
    output_p="$output_p\n\t- Created file: /etc/modprobe.d/$l_mname.conf with install $l_mname /bin/false"
    
    # Remediation - Create file with blacklist dccp
    backup_file "/etc/modprobe.d/blacklist-$l_mname.conf"
    echo -e "blacklist $l_mname" > /etc/modprobe.d/"blacklist-$l_mname".conf
    output_p="$output_p\n\t- Created file: /etc/modprobe.d/blacklist-$l_mname.conf with blacklist $l_mname"
    
    # Unload the module from the kernel
    if lsmod | grep -q "$l_mname"; then
      output_p="$output_p\n\t- Unloading module \"$l_mname\""
      modprobe -r "$l_mname"
    fi
  fi

  # Check if the module is available in any installed kernel
  if ! lsmod | grep -q "$l_mname"; then
    # Remediation - Create file with blacklist dccp if not available in any installed kernel
    output_p="$output_p\n\t- Module \"$l_mname\" is not loaded, but checking installed kernels"
    backup_file "/etc/modprobe.d/blacklist-$l_mname.conf"
    echo -e "blacklist $l_mname" > /etc/modprobe.d/"blacklist-$l_mname".conf
    output_p="$output_p\n\t- Created file: /etc/modprobe.d/blacklist-$l_mname.conf with blacklist $l_mname"
  else
    output_f="$output_f\n\t- Module \"$l_mname\" is loaded in the kernel but should be disabled"
  fi

  # Final remediation result
  if [ -z "$output_f" ]; then
    echo -e "\n- Remediation result [DCCP Module Disable]: ** SUCCESS **"
    echo -e "$output_p"
  else
    echo -e "\n- Remediation result [DCCP Module Disable]: ** everythingisOK **"
    echo -e "\n- Reason(s) for remediation failure:\n$output_f"
  fi
}

modules=('dccp' 'ticp' 'rds' 'sctp')
for m in "${modules[@]}";do 
  module-rem $m
done
