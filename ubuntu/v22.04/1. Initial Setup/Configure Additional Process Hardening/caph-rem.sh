#!/bin/bash

installed-rem(){
  echo -e "\n- Audit for \"$@ installed check\":"
  if [[ -n "$(dpkg-query -s $@ 2> /dev/null)" ]]; then
    apt purge $@ -y &> /dev/null
    echo -e "\t- Remediation: **SUCCESS**"
  else 
    echo -e "\t- Remediation: Everything is **OK**"
  fi
}

layout-rand-rem(){
  echo -e "\n- Remeidiation for ensuring address space layout randomization is enabled:"
  if [[ -z "$( /usr/lib/systemd/systemd-sysctl --cat-config | grep  'kernel.randomize_va_space = 2')" ]]; then
    printf "%s\n" "kernel.randomize_va_space = 2" >> /etc/sysctl.d/10-layout-randomize.conf  
    sysctl -w kernel.randomize_va_space=2  
    echo -e "\t- Remediation: **SUCCESS**"
  else
    echo -e "\t- Remediation: Everything is **OK**"
  fi
}

ptrace_scope-rem(){
  echo -e "\n- Remeidiation for ensuring 'ptrace_scope' is restricted:"
  if [[ -z "$( /usr/lib/systemd/systemd-sysctl --cat-config | grep  'kernel.yama.ptrace_scope = 1')" ]]; then
    printf "%s\n" "kernel.yama.ptrace_scope = 1" >> /etc/sysctl.d/10-ptrace.conf  
    sysctl -w kernel.randomize_va_space=2  
    echo -e "\t- Remediation: **SUCCESS**"
  else
    echo -e "\t- Remediation: Everything is **OK**"
  fi
}

coredump-rem(){
  if [[ -n "$(systemctl list-unit-files | grep coredump)" ]]; then
    echo -e "Storage=none\nProcessSizeMax=0" >> /etc/systemd/coredump.conf
    systemctl daemon-reload  
    echo -e "\t - Systemd-coredump was installed [fixed it/disabled it]"
  fi

  if [[ -z "$(grep -Ps -- '^\h*\*\h+hard\h+core\h+0\b' /etc/security/limits.conf  /etc/security/limits.d/*)" ]]; then
    echo '* hard core 0' >> /etc/security/limits.d/10-coredump.conf
    echo -e "\t - Configured '/etc/security/limits.d/' for for restricting coredumps."
  fi

  if [[ -z "$( /usr/lib/systemd/systemd-sysctl --cat-config | grep  'fs.suid_dumpable = 0')" ]]; then
    printf "%s\n" "fs.suid_dumpable = 0" >> /etc/sysctl.d/10-ptrace.conf  
    sysctl -w fs.suid_dumpable = 0  
    echo -e "\t- Remediation: **SUCCESS**"
  else
    echo -e "\t- Remediation: Everything is **OK**"
  fi
}


pkgs=('prelink' 'apport')
for pkg in "${pkgs[@]}";do 
  installed-rem "$pkg"
done

layout-rand-rem
ptrace_scope-rem
coredump-rem
