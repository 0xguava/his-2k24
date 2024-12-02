#!/bin/bash

service-chk() {
  local pkg_output=''
  local output_p=''
  local output_f=''
  local logvr=1
  local pkg_name=$(echo $1 | cut -d\. -f1)

  if dpkg-query -s "$pkg_name" &>/dev/null; then
    pkg_output="$pkg_output\n\t - $pkg_name is installed."
  else
    pkg_output="$pkg_output\n\t - $pkg_name isn't installed."
  fi

  if systemctl is-enabled "$1" 2>/dev/null | grep -q 'enabled'; then
    output_f="$output_f\n\t - $1 is enabled."
    logvr=0
  else
    output_p="$output_p\n\t - $1 is NOT enabled."
  fi

  if systemctl is-active "$1" 2>/dev/null | grep -q '^active'; then
    output_f="$output_f\n\t - $1 is active."
    logvr=0
  else
    output_p="$output_p\n\t - $1 is NOT active."
  fi


}
