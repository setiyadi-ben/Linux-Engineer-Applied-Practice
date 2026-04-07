#!/bin/bash

###############################################################
# OFFLINE OPENJDK INSTALLATION SCRIPT FOR UBUNTU
# 
# REQUIREMENTS:
# 1. THIS SCRIPT MUST BE IN THE SAME DIRECTORY AS:
#    openjdk-*_linux-x64_bin.tar.gz (exactly one matching file)
# 2. NO INTERNET REQUIRED (OFFLINE INSTALLATION)
###############################################################

###############################################################
# CONFIGURATION SECTION - CHANGE IF NEEDED
###############################################################

# [CHANGE THIS FOR DIFFERENT INSTALL LOCATION]
# Default Java installation directory
INSTALL_DIR="/usr/lib/jvm"

###############################################################
# INSTALLATION SECTION - NO CHANGES NEEDED BELOW
###############################################################

# Find JDK tarball using wildcard pattern
echo "Searching for JDK tarball..."
JDK_TARBALLS=(openjdk-*_linux-x64_bin.tar.gz)

# Validate tarball existence
if [ ${#JDK_TARBALLS[@]} -eq 0 ]; then
  echo -e "\nERROR: No JDK tarball found!"
  echo -e "1. Download OpenJDK and place in this directory"
  echo -e "2. File must match pattern: openjdk-*_linux-x64_bin.tar.gz"
  echo -e "3. Run this script again\n"
  exit 1
elif [ ${#JDK_TARBALLS[@]} -gt 1 ]; then
  echo -e "\nERROR: Multiple JDK tarballs found:"
  printf '• %s\n' "${JDK_TARBALLS[@]}"
  echo -e "\nKeep only one file and try again\n"
  exit 1
fi

# Set detected values
JDK_TARBALL="${JDK_TARBALLS[0]}"
VERSION=$(echo "$JDK_TARBALL" | sed 's/openjdk-\(.*\)_linux-x64_bin.tar.gz/\1/')
JDK_PATH="$INSTALL_DIR/jdk-$VERSION"

echo -e "\nDetected components:"
echo "• Tarball:    $JDK_TARBALL"
echo "• Version:    $VERSION"
echo "• Install to: $JDK_PATH"

# Create Java directory with proper permissions
echo -e "\nCreating installation directory..."
sudo mkdir -p "$INSTALL_DIR"

# Extract JDK with progress
echo -e "\nInstalling JDK..."
sudo tar -xzf "$JDK_TARBALL" -C "$INSTALL_DIR"

# Configure system alternatives
echo -e "\nSetting system-wide Java alternatives..."
sudo update-alternatives --install "/usr/bin/java" "java" "$JDK_PATH/bin/java" 1000
sudo update-alternatives --install "/usr/bin/javac" "javac" "$JDK_PATH/bin/javac" 1000

# Force-set as default
echo -e "\nMaking this JDK the system default..."
sudo update-alternatives --set java "$JDK_PATH/bin/java"
sudo update-alternatives --set javac "$JDK_PATH/bin/javac"

# Add environment variables
echo -e "\nConfiguring user environment..."
{
  echo -e "\n# OpenJDK Automatic Configuration"
  echo "export JAVA_HOME='$JDK_PATH'"
  echo "export PATH=\"\$JAVA_HOME/bin:\$PATH\""
} | tee -a ~/.bashrc >/dev/null

# Load new environment settings
source ~/.bashrc

# Final verification
echo -e "\nVerifying installation:"
java -version
javac -version

echo -e "\nSUCCESS! OpenJDK $VERSION is now installed."
echo -e "Close and reopen terminal sessions to refresh all environment variables."