#!/bin/bash
set -e

# Function to ensure all group IDs have entries in /etc/group
ensure_groups() {
    # Get the current user's groups
    CURRENT_GROUPS=$(id -G 2>/dev/null || echo "")
    
    if [ -z "$CURRENT_GROUPS" ]; then
        return 0
    fi
    
    # For each group ID, ensure it has an entry in /etc/group
    for GID in $CURRENT_GROUPS; do
        # Check if group entry exists
        if ! getent group "$GID" > /dev/null 2>&1; then
            # Create a group entry for this GID
            # Use a generic name like "group137"
            GROUP_NAME="group${GID}"
            
            # Try to get group name from host if /etc/group is mounted, otherwise use generic name
            if [ -f /host/etc/group ]; then
                HOST_GROUP_NAME=$(grep ":${GID}:" /host/etc/group 2>/dev/null | cut -d: -f1 | head -n1)
                if [ -n "$HOST_GROUP_NAME" ]; then
                    GROUP_NAME="$HOST_GROUP_NAME"
                fi
            fi
            
            # Add group entry using sudo (user has NOPASSWD sudo)
            echo "${GROUP_NAME}:x:${GID}:" | sudo tee -a /etc/group > /dev/null 2>&1 || true
        fi
    done
}

# Ensure groups are set up before executing the command
# Run this in a way that persists across shell invocations
ensure_groups

# Also ensure groups are set up in a subshell-safe way
# This handles cases where the shell calls groups during initialization
export GROUPS_SETUP=1

# Execute the original command
exec "$@"
