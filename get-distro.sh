#!/bin/bash

# 1. Detect Architecture (e.g., x86_64 or aarch64/arm64)
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ]; then
    ARCH_SUFFIX="-arm64"
else
    ARCH_SUFFIX="" # Leave blank for standard x86_64
fi

# 2. Read OS Name and Version from /etc/os-release
if [ -f /etc/os-release ]; then
    # Source the file to get variables like $NAME and $VERSION_ID
    . /etc/os-release
    
    # Fallback to ID if NAME is empty
    OS_NAME="${NAME:-$ID}"
    
    # --- CHANGED HERE ---
    # Strip away everything after the first dot to extract only the major version.
    # Works for "10.1" -> "10", "24.04" -> "24", or "9" -> "9"
    RAW_VER="${VERSION_ID:-$VERSION}"
    OS_VER=$(echo "$RAW_VER" | cut -d'.' -f1)
else
    echo "unknown-linux"
    exit 1
fi

# 3. Combine them into a raw string
RAW_STRING="${OS_NAME}${ARCH_SUFFIX} ${OS_VER}"

# 4. Clean the string to make it URL and filename safe:
SAFE_OS_STRING=$(echo "$RAW_STRING" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '-' | sed 's/-$//')

# 5. Output ONLY the clean string
echo "$SAFE_OS_STRING"