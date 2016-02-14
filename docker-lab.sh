#!/usr/bin/env bash

# =============================================================================
# Docker Lab Installer v1.0
# =============================================================================
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# AppCatalyst Lab: Automated install of Docker Lab
# Author: Paul Gifford <pgifford@vmware.com>
# Blog Post: http://www.cloudcanuck.ca/posts/appacatalyst-lab-installer
# Lessons Learned from: Sebastian Weigand <sweigand@vmware.com>
#

LOGFILE=docker_lab_install.log
VAGRANT_URL=https://releases.hashicorp.com/vagrant/1.8.1/vagrant_1.8.1.dmg
DOCKERTOOLBOX_URL=https://github.com/docker/toolbox/releases/download/v1.10.1/DockerToolbox-1.10.1.pkg

# Colors
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"

clear
echo ""
echo -e "$COL_GREEN Docker Lab Installer v1.0 $COL_RESET"
echo ""
read -p "Press [Enter] to begin..."


# Write everything to the screen, and also to a log file.
echo -e "\n\nBegan new run of Docker Lab Installer at $(date +%T) on $(date +%m/%d/%y)" >> $LOGFILE
exec > >(tee -a $LOGFILE)
echo ""

# =================================================================================
# Install Docker Lab components
# =================================================================================

# I consider Homebrew, git, wget, and homebrew-based Python (which gives pip),
# Vagrant (with plugins), Docker Toolbox, Docker Machine, Docker Cloud & Ansible
# to be essential tools for the Docker Lab.
#

COUNT=0

# Recurse this to achieve a somewhat idempotent execution:
check_system() {

  STATE=OK

  # In case we loop too many times, keep this equal to # of ifs:
  let COUNT+=1
  if [ $COUNT -gt 6 ]; then
    echo -e "$COL_RED Something happened and this script got stuck in a loop, please have a look and correct. Please check $LOGFILE. $COL_RESET"
    exit 1
  fi

  if [ $COUNT -eq 1 ]; then
    CHECK_VERB="Checking"
  else
    CHECK_VERB="\nRechecking"
  fi

  echo -e "$COL_GREEN ${CHECK_VERB} your Mac for Docker Lab Setup... $COL_RESET"
  echo ""

  # Check for Homebrew
  echo -n "Homebrew:                             "
  if command -v brew &> /dev/null; then
    echo -e "$COL_GREEN[ OK ]$COL_RESET"

  # No Homebrew:
  else
    echo -e "$COL_RED[ Missing ]$COL_RESET"
    echo "Requesting an install of Homebrew..."
    echo ""
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    echo ""
    STATE=Bad
  fi

  # Check for wget, because curl isn't as sexy as wget:
  echo -n "wget:                                 "
  if command -v wget > /dev/null; then
    echo -e "$COL_GREEN[ OK ]$COL_RESET"

  else
    echo -e "$COL_RED[ Missing ]$COL_RESET"
    echo "Installing wget..."
    brew install wget >> $LOGFILE 2>&1
    echo ""
    STATE=Bad
  fi

  # Check for git:
  echo -n "git:                                  "
  if git --version | grep -qv Apple > /dev/null; then
    echo -e "$COL_GREEN[ OK ]$COL_RESET"

  else
    echo -e "$COL_RED[ Missing ]$COL_RESET"
    echo "Installing git..."
    brew install git >> $LOGFILE 2>&1
    echo ""
    STATE=Bad
  fi

  # Check for Ansible in Homebrew:
  echo -n "Ansible:                              "
  if brew list ansible &> /dev/null; then
    echo -e "$COL_GREEN[ OK ]$COL_RESET"

  else
    echo -e "$COL_RED[ Missing ]$COL_RESET"
    echo "Installing Ansible..."
    brew install ansible >> $LOGFILE 2>&1
    echo ""
    STATE=Bad
  fi

    # Check for Python in Homebrew:
  # echo -n "Python:                               "
  # if brew list python &> /dev/null; then
  #  echo -e "$COL_GREEN[ OK ]$COL_RESET"

  # else
  #   echo -e "$COL_RED[ Missing ]$COL_RESET"
  #   echo "Installing Python..."
  #   brew install python >> $LOGFILE 2>&1
  #   echo ""
  #   STATE=Bad
  # fi

  # Check for Packer in Homebrew:
  echo -n "Packer:                               "
  if brew list packer &> /dev/null; then
    echo -e "$COL_GREEN[ OK ]$COL_RESET"

  else
    echo -e "$COL_RED[ Missing ]$COL_RESET"
    echo "Installing Packer..."
    brew install packer >> $LOGFILE 2>&1
    echo ""
    STATE=Bad
  fi

  # Check and Install Docker Toolbox:
  echo -n "Docker Toolbox:                       "
  if pkgutil --pkg-info io.docker.pkg.docker &> /dev/null; then
    echo -e "$COL_GREEN[ OK ]$COL_RESET"

  else
    echo -e "$COL_RED[ Missing ]$COL_RESET"
    echo "Downloading Docker Toolbox..."
    wget -c -q $DOCKERTOOLBOX_URL >> $LOGFILE 2>&1
    echo ""
    echo "Installing Docker Toolbox..."
    sudo installer -pkg "DockerToolbox-1.10.1.pkg" -target / >> $LOGFILE 2>&1
    echo ""
    STATE=Bad
  fi

  # Check for Docker Cloud in Homebrew:
  echo -n "Docker Cloud:                         "
  if brew list docker-cloud &> /dev/null; then
    echo -e "$COL_GREEN[ OK ]$COL_RESET"

  else
    echo -e "$COL_RED[ Missing ]$COL_RESET"
    echo "Installing Docker Cloud..."
    brew install docker-cloud >> $LOGFILE 2>&1
    echo ""
    STATE=Bad
  fi

  # Check and Install Vagrant:
  echo -n "Vagrant:                              "
  if pkgutil --pkg-info com.vagrant.vagrant &> /dev/null; then
    echo -e "$COL_GREEN[ OK ]$COL_RESET"

  else
    echo -e "$COL_RED[ Missing ]$COL_RESET"
    echo "Downloading Vagrant..."
    wget -c -q $VAGRANT_URL >> $LOGFILE 2>&1
    echo ""
    echo "Installing Vagrant..."
    echo ""
    hdiutil attach vagrant_1.8.1.dmg >> $LOGFILE 2>&1
    sudo installer -pkg "/Volumes/Vagrant/Vagrant.pkg" -target / >> $LOGFILE 2>&1
    umount "/Volumes/Vagrant/" >> $LOGFILE 2>&1
    STATE=Bad
  fi

}

until [[ $STATE == "OK" ]]; do
  check_system
done

echo "Completed last new run of Docker Lab Installer at $(date +%T) on $(date +%m/%d/%y)" >> $LOGFILE 2>&1
echo ""
echo ""
echo -e "$COL_GREEN Your Docker Lab is ready to roll. $COL_RESET"
echo ""
echo ""
read -p "Press [Enter] to continue..."

# EOF
