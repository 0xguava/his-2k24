#!/usr/bin/env bash
## <-- Check started -->
fs_kernel_module_chk() {
  l_output="" l_output2="" l_output3="" l_dl="" # Unset output variables
  l_mname="$@"                                  # set module name
  l_mtype="fs"                                  # set module type
  l_searchloc="/lib/modprobe.d/*.conf /usr/local/lib/modprobe.d/*.conf /run/modprobe.d/*.conf
/etc/modprobe.d/*.conf"
  l_mpath="/lib/modules/**/kernel/$l_mtype"
  l_mpname="$(tr '-' '_' <<<"$l_mname")"
  l_mndir="$(tr '-' '/' <<<"$l_mname")"
  module_loadable_chk() {
    # Check if the module is currently loadable
    l_loadable="$(modprobe -n -v "$l_mname")"
    [ "$(wc -l <<<"$l_loadable")" -gt "1" ] && l_loadable="$(grep -P "(^\h*install|\b$l_mname)\b" <<<"$l_loadable")"
    if grep -Pq -- '^\h*install \/bin\/(true|false)' <<<"$l_loadable"; then
      l_output="\n\t - module: \"$l_mname\" is not loadable: \"$l_loadable\""
    else
      l_output2=" - module: \"$l_mname\" is loadable: \"$l_loadable\""
    fi
  }
  module_loaded_chk() {
    # Check if the module is currently loaded
    if ! lsmod | grep "$l_mname" >/dev/null 2>&1; then
      l_output="$l_output\n\t - module: \"$l_mname\" is not loaded"
    else
      l_output2="$l_output2\n - module: \"$l_mname\" is loaded"
    fi
  }
  module_deny_chk() {
    # Check if the module is deny listed
    l_dl="y"
    if modprobe --showconfig | grep -Pq -- '^\h*blacklist\h+'"$l_mpname"'\b'; then
      l_output="$l_output\n - module: \"$l_mname\" is deny listed in: \"$(grep -Pls -"^\h*blacklist\h+$l_mname\b" $l_searchloc)\""
    else
      l_output2="$l_output2\n - module: \"$l_mname\" is not deny listed"
    fi
  }
  # Check if the module exists on the system
  for l_mdir in $l_mpath; do
    if [ -d "$l_mdir/$l_mndir" ] && [ -n "$(ls -A $l_mdir/$l_mndir)" ]; then
      l_output3="\n\t - \"$l_mdir\""
      [ "$l_dl" != "y" ] && module_deny_chk
      if [ "$l_mdir" = "/lib/modules/$(uname -r)/kernel/$l_mtype" ]; then
        module_loadable_chk
        module_loaded_chk
      fi
    else
      l_output="$l_output\n - module: \"$l_mname\" doesn't exist in \"$l_mdir\""
    fi
  done
  # Report results. If no failures output in l_output2, we pass
  [ -n "$l_output3" ] && echo -e "\tModule: \"$l_mname\" exists in:$l_output3"
  if [ -z "$l_output2" ]; then
    echo -e "\t- Audit Result: **PASS** for \"$l_mname\"\n\t $l_output"
  else
    echo -e "\t- Audit Result: **FAIL** for \"$l_mname\"\n\t - Reason(s) for audit failure:\n\t$l_output2"
    [ -n "$l_output" ] && echo -e "\t- Correctly set:\t$l_output"
  fi
}

fs_kernel_module=("cramfs" "freevxfs" "hfs" "hfsplus" "jffs2" "squashfs" "udf" "usb-storage")

echo -e "\n\nAudit for file system kernel moudles."
for module in "${fs_kernel_module[@]}"; do
  fs_kernel_module_chk $module
  echo -e "\n"
done

## <-- Check End -->
