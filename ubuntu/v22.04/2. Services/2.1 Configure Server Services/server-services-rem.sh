#!/bin/bash

service-rem(){
  local logvr=1

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
}
