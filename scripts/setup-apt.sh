#!/bin/bash

GRR_RAW_REPO_URL="https://raw.githubusercontent.com/greenroom-robotics/public_packages/main"

echo "Setting up debian lists..."
sudo curl -sSL "${GRR_RAW_REPO_URL}/debian/keyring.asc" -o /etc/apt/trusted.gpg.d/greenroom-robotics-public-packages-keyring.asc
sudo curl -SsL "${GRR_RAW_REPO_URL}/debian/greenroom-robotics-public-packages.list" -o /etc/apt/sources.list.d/greenroom-robotics-public-packages.list

if [ -z "$ROS_DISTRO" ]; then
    echo "Error: Could not detect a ROS installation as ROS_DISTRO is not set."
    exit 1
fi

echo "Detected ROS Distribution: ${ROS_DISTRO}"

# Download the yaml file to a sensible location
# Creating a custom directory inside /etc/ros/ keeps it organized alongside standard rosdep files
sudo mkdir -p /etc/ros/custom_rosdep
ROSDEP_YAML_LOC="/etc/ros/custom_rosdep/greenroom-robotics-rosdep-${ROS_DISTRO}.yaml"

# Assuming the repository is public, construct the raw GitHub URL
ROSDISTRO_YAML_URL="${GRR_RAW_REPO_URL}/rosdep/rosdep-${ROS_DISTRO}.yaml"

echo "Downloading rosdep configuration from ${ROSDISTRO_YAML_URL}..."
sudo curl -f -sSL "$ROSDISTRO_YAML_URL" -o "$ROSDEP_YAML_LOC"

if [ $? -ne 0 ]; then
    echo "Error: Failed to download the rosdep yaml file. Check if it exists for ${ROS_DISTRO}"
    exit 1
fi

# Check for rosdep initialization
if [ ! -d "/etc/ros/rosdep" ]; then
    echo "/etc/ros/rosdep not found. Initializing rosdep..."
    
    SETUP_SCRIPT="/opt/ros/${ROS_DISTRO}/setup.sh"
    if [ -f "$SETUP_SCRIPT" ]; then
        source "$SETUP_SCRIPT"
    else
        echo "Error: ${SETUP_SCRIPT} does not exist. Cannot initialize rosdep"
        exit 1
    fi
    
    # rosdep init requires sudo as it creates system-wide directories in /etc/ros
    sudo rosdep init
fi

# Create the local list file
LIST_FILE="/etc/ros/rosdep/sources.list.d/50-greenroom-robotics-local.list"

echo "Adding local rosdep source to ${LIST_FILE}..."
echo "yaml file://${ROSDEP_YAML_LOC}" | sudo tee "$LIST_FILE" > /dev/null

# Run rosdep update
# This is explicitly run WITHOUT sudo to prevent permission issues in the user's ~/.ros/ directory
echo "Running rosdep update for ${ROS_DISTRO}..."
rosdep update --rosdistro="${ROS_DISTRO}"

echo "Successfully configured local rosdep for Greenroom Robotics"