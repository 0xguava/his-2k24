#!/bin/bash

daemon-rem() {
  # Check for arguments
  if [ "$#" -ne 1 ]; then
    echo "Usage: $0 --chrony | --timesyncd"
    exit 1
  fi

  # Determine the selected daemon
  case "$1" in
  --chrony)
    echo "Configuring Chrony for time synchronization..."

    # Install Chrony
    echo "Installing chrony..."
    if apt install -y chrony; then
      echo "Chrony installed successfully."
    else
      echo "Failed to install Chrony."
      exit 1
    fi

    # Stop and mask systemd-timesyncd
    echo "Stopping and masking systemd-timesyncd..."
    systemctl stop systemd-timesyncd.service
    systemctl mask systemd-timesyncd.service

    echo "Chrony is now configured for time synchronization."
    ;;
  --timesyncd)
    echo "Configuring systemd-timesyncd for time synchronization..."

    # Remove Chrony
    echo "Removing Chrony..."
    if apt purge -y chrony && apt autoremove -y; then
      echo "Chrony removed successfully."
    else
      echo "Failed to remove Chrony."
      exit 1
    fi

    # Enable and start systemd-timesyncd
    echo "Enabling and starting systemd-timesyncd..."
    systemctl unmask systemd-timesyncd.service
    systemctl enable systemd-timesyncd.service
    systemctl start systemd-timesyncd.service

    echo "systemd-timesyncd is now configured for time synchronization."
    ;;
  *)
    echo "Invalid option. Use --chrony or --timesyncd."
    exit 1
    ;;
  esac
}

daemon-rem $@
