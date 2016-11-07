#!/usr/bin/env bash

# Example usage:
#     ./freeze-requirement.sh <target-spec-file>

set -e

# Check arg count
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <target-spec-file>"
  exit 1
fi

TARGET_SPEC_FILE=$1

# Look for required Palette packages in the .spec file
# Theses packages by convention look like
#   Requires: <package-name>
# in the .spec file. Note that only on package is
# is listed in such lines.
REQUIRED_PACKAGES=$(cat ${TARGET_SPEC_FILE} | grep -oP "(?<=^Requires: )(palette|insight)\S*(?=\s*$)")
for PACKAGE_NAME in ${REQUIRED_PACKAGES}; do
    # Query the latest RPM version number of the specified package
    LATEST_VERSION_NOARCH=$(curl https://rpm.palette-software.com/centos/dev/noarch/ | grep ${PACKAGE_NAME} | sed -nr "s/.*$PACKAGE_NAME-([v]?[0-9.-]+)\.noarch.*/\1/p")
    LATEST_VERSION_X86_64=$(curl https://rpm.palette-software.com/centos/dev/x86_64/ | grep ${PACKAGE_NAME} | sed -nr "s/.*$PACKAGE_NAME-([v]?[0-9.-]+)\.x86_64.*/\1/p")
    LATEST_VERSION=$(echo -e "${LATEST_VERSION_NOARCH}\n${LATEST_VERSION_X86_64}" | sort -V | tail -1)

    if [ -z "${LATEST_VERSION}" ]; then
        echo "Failed to query latest version of package: '${PACKAGE_NAME}'!"
        exit 1
    fi

    # Replace the requirement line in the specified spec file
    # For example this script would turn a line like this
    #   Requires: palette-insight-agent
    # into
    #   Requires: palette-insight-agent = 2.0.11
    sed -i "s/Requires: ${PACKAGE_NAME}/Requires: ${PACKAGE_NAME} = ${LATEST_VERSION}/g" ${TARGET_SPEC_FILE}
done 
