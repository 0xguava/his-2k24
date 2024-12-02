#!/bin/bash

gpg-keys-chk(){
  echo -e "\n\nAudit for gpg-keys for apt:"
  if [[ -z "$(apt-key list 2>&1)" ]]; then
    echo -e "\t- Audit result: **FAIL** [gpg-keys for apt]" 
  elif [[ -n "$(apt-key list 2>&1 | grep -i 'deprecated')" ]]; then
    echo -e "\t- Audit result: **FAIL** [gpg-keys for apt]" 
    echo -e "\t- gpg keys for apt are deprecated."
  else
    echo -e "\t- Audit result: **PASS** [gpg-keys for apt]" 
  fi
}

pkg-repo-chk(){
  echo -e "\n\nAudit for Package Manager Repositories:"
  # Configure your package manager repositories according to site policy.  
}

update-chk(){
  echo -e "\n\nAudit for System Update:"
  apt update &> /dev/null
  if [[ -z "$(apt -s upgrade 2> /dev/null | grep -i '0 upgraded')" ]]; then
    echo -e "\t- Audit result: **FAIL** [System update]" 
    echo -e "\t- System needs to be updated."
  else
    echo -e "\t- Audit result: **PASS** [System update]" 
    echo -e "\t- System is updated."
  fi
}

gpg-keys-chk
update-chk
