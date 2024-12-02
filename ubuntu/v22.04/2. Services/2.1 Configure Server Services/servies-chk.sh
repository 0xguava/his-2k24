#!/bin/bash

service-chk() {
  local pkg_output=''
  local output_p=''
  local output_f=''
  local logvr=1

  if dpkg-query -s autofs &>/dev/null; then
    pkg_output="$pkg_output\n\t - autofs is installed."
  else
    pkg_output="$pkg_output\n\t - autofs isn't installed."
  fi

  if systemctl is-enabled autofs.service 2>/dev/null | grep -q 'enabled'; then
    output_f="$output_f\n\t - autofs.service is enabled."
    logvr=0
  else
    output_p="$output_p\n\t - autofs.service is NOT enabled."
  fi

  if systemctl is-active autofs.service 2>/dev/null | grep -q '^active'; then
    output_f="$output_f\n\t - autofs.service is active."
    logvr=0
  else
    output_p="$output_p\n\t - autofs.service is NOT active."
  fi
}
