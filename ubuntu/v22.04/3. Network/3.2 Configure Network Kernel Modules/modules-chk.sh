#!/bin/bash 

module-chk() {
  local l_mname="$@"
  local output_p=""
  local output_f=""

  # Check if the module is available in the running kernel
  if lsmod | grep -q "$l_mname"; then
    output_p="$output_p\n\t- Module \"$l_mname\" is loaded in the kernel"
    # Check if the module is denied in modprobe.d
    if grep -q "blacklist $l_mname" /etc/modprobe.d/*; then
      output_p="$output_p\n\t- Module \"$l_mname\" is deny-listed in modprobe.d"
    else
      output_f="$output_f\n\t- Module \"$l_mname\" is not deny-listed in modprobe.d"
    fi
    # Check if the module is marked as un-loadable (install /bin/false)
    if grep -q "install $l_mname /bin/false" /etc/modprobe.d/*; then
      output_p="$output_p\n\t- Module \"$l_mname\" is set to un-loadable (/bin/false)"
    else
      output_f="$output_f\n\t- Module \"$l_mname\" is not set to un-loadable"
    fi
    # Check if the module is loaded in the kernel, and unload it if necessary
    if lsmod | grep -q "$l_mname"; then
      output_p="$output_p\n\t- Unloading module \"$l_mname\""
      modprobe -r "$l_mname"
    fi
  fi

  # Check if the module is available in any installed kernel
  if ! lsmod | grep -q "$l_mname"; then
    # Check if the module is deny-listed in modprobe.d
    if grep -q "blacklist $l_mname" /etc/modprobe.d/*; then
      output_p="$output_p\n\t- Module \"$l_mname\" is deny-listed in modprobe.d"
    else
      output_f="$output_f\n\t- Module \"$l_mname\" is not deny-listed in modprobe.d"
    fi
  else
    output_f="$output_f\n\t- Module \"$l_mname\" is loaded in the kernel but should be disabled"
  fi

  # Final audit result
  if [ -z "$output_f" ]; then
    echo -e "\n- Audit result [DCCP Module Check]: ** SUCCESS **"
    echo -e "$output_p"
  else
    echo -e "\n- Audit result [DCCP Module Check]: ** everythingisOK **"
    echo -e "\n- Reason(s) for audit failure:\n$output_f"
  fi
}

modules=('dccp' 'ticp' 'rds' 'sctp')
for m in "${modules[@]}";do 
  module-chk $m
done

