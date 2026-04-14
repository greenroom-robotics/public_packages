#!/bin/bash

set -ev

#pushd debian
#
## Packages & Packages.gz
#dpkg-scanpackages --multiversion . > Packages
#gzip -k -f Packages
#
## Release, Release.gpg & InRelease
#apt-ftparchive release . > Release
#gpg --default-key "${GPG_KEY_NAME}" -abs -o - Release > Release.gpg
#gpg --default-key "${GPG_KEY_NAME}" --clearsign -o - Release > InRelease
#
#popd

# Define the target ROS versions
ROS_VERSIONS=("noetic" "foxy" "galactic" "humble" "iron" "rolling" "jazzy")

# Find all .deb files in the current directory, extract the part before 
# the first '_', and get the unique names.
UNIQUE_NAMES=$(find debian -maxdepth 1 -name "*.deb" -printf "%f\n" | cut -d'_' -f1 | sed 's/^ros-[a-z]*-//' | sort -u)

pushd rosdep

if [ -n "$UNIQUE_NAMES" ]; then
    for VERSION in "${ROS_VERSIONS[@]}"; do
        YAML_FILE="rosdep-${VERSION}.yaml"
        
        # Initialize an empty file (overwrites if it already exists)
        > "$YAML_FILE"
        
        # Populate the yaml file with the required format
        for PKG in $UNIQUE_NAMES; do
            echo "${PKG}:" >> "$YAML_FILE"
            echo "    ubuntu: ros-${VERSION}-${PKG}" >> "$YAML_FILE"
        if [ "${PKG//-/_}" != "${PKG}" ]; then
            echo "${PKG//-/_}:" >> "$YAML_FILE"
            echo "    ubuntu: ros-${VERSION}-${PKG}" >> "$YAML_FILE"
        fi
        done
        
        echo "Successfully generated ${YAML_FILE}"
    done
else
    echo "No .deb files found. Skipping rosdep yaml generation."
fi

popd
