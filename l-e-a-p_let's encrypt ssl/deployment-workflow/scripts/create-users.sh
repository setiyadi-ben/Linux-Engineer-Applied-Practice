#!/bin/bash
# Clear terminal screen
clear
# =========================================================
# HEADER
# =========================================================
echo "========================================="
echo "        Linux User Management"
echo "========================================="
echo
# =========================================================
# SHOW AVAILABLE USERS
# =========================================================
echo "Available users on this system:"
echo
# Show only normal users
# Hide root, nobody, daemon/system users, and nologin users
awk -F: '$3 >= 1000 && $1 != "nobody" && $7 !~ /nologin/ {print " - " $1}' /etc/passwd
echo
echo "========================================="
echo
# =========================================================
# MAIN MENU
# =========================================================
echo "Please choose an option:"
echo "  1) Create new user"
echo "  2) Delete existing user"
echo
# Ask for menu selection
read -p "Enter your choice [1-2]: " ACTION
echo
# =========================================================
# MAIN LOGIC
# =========================================================
case "$ACTION" in
    # =====================================================
    # CREATE USER
    # =====================================================
    1)
        # Ask for username
        read -p "Enter new username: " USERNAME
        # Check if user already exists
        if id "$USERNAME" &>/dev/null; then
            echo
            echo "[ERROR] User '$USERNAME' already exists."
            exit 1
        fi
        # Ask password silently
        read -s -p "Enter password: " PASSWORD
        echo
        echo
        echo "Creating user..."
        # Create user with home directory and bash shell
        sudo useradd -m -s /bin/bash "$USERNAME" && \
        # Set password
        echo "$USERNAME:$PASSWORD" | sudo chpasswd && \
        # Add into sudo group
        sudo usermod -aG sudo "$USERNAME"
        # Check result
        if [[ $? -eq 0 ]]; then
            echo
            echo "[SUCCESS] User '$USERNAME' has been created and added to sudo group."
        else
            echo
            echo "[ERROR] Failed to create user."
        fi
        ;;
    # =====================================================
    # DELETE USER
    # =====================================================
    2)
        # Build array of available users
        mapfile -t USERS < <(awk -F: '$3 >= 1000 && $1 != "nobody" && $7 !~ /nologin/ {print $1}' /etc/passwd)
        
        # Check if there are users to delete
        if [[ ${#USERS[@]} -eq 0 ]]; then
            echo "[ERROR] No users available to delete."
            exit 1
        fi
        
        echo "Select user to delete:"
        echo
        # Display users with numbers
        for i in "${!USERS[@]}"; do
            echo "  $((i+1))) ${USERS[$i]}"
        done
        echo
        # Ask for selection
        read -p "Enter your choice [1-${#USERS[@]}]: " SELECTION
        echo
        
        # Validate selection
        if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [[ "$SELECTION" -lt 1 ]] || [[ "$SELECTION" -gt ${#USERS[@]} ]]; then
            echo "[ERROR] Invalid selection."
            exit 1
        fi
        
        # Get username from selection (array is 0-indexed)
        USERNAME="${USERS[$((SELECTION-1))]}"
        
        # Prevent deleting root (extra safety)
        if [[ "$USERNAME" == "root" ]]; then
            echo
            echo "[ERROR] Root user cannot be deleted."
            exit 1
        fi
        
        echo "User selected : $USERNAME"
        echo "Home directory: /home/$USERNAME"
        echo
        echo "Authentication required to continue."
        # Request sudo authentication
        sudo -v
        # Check authentication
        if [[ $? -ne 0 ]]; then
            echo
            echo "[ERROR] Authentication failed."
            exit 1
        fi
        echo
        echo "Deleting user..."
        # Delete user and home directory
        sudo userdel -r "$USERNAME"
        # Check result
        if [[ $? -eq 0 ]]; then
            echo
            echo "[SUCCESS] User '$USERNAME' has been deleted successfully."
        else
            echo
            echo "[ERROR] Failed to delete user '$USERNAME'."
        fi
        ;;
    # =====================================================
    # INVALID OPTION
    # =====================================================
    *)
        echo "[ERROR] Invalid selection."
        exit 1
        ;;
esac