#!/bin/bash
# ============================================================
# User Manager v2.0 - Advanced user account management
# ============================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
LOG_FILE="/var/log/user_manager.log"
PASSWORD_POLICY=true
MIN_PASS_LEN=12
MAX_DAYS=90
WARN_DAYS=14

# Function to show usage
usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "User Management:"
    echo "  -a <username>  Add new user"
    echo "  -d <username>  Delete user"
    echo "  -m <username>  Modify user"
    echo "  -p <username>  Change user password"
    echo "  -l             List all users"
    echo "  -i <username>  Show user information"
    echo ""
    echo "Group Management:"
    echo "  -g add <user> <group>     Add user to group"
    echo "  -g remove <user> <group>  Remove user from group"
    echo "  -g list <user>            List user groups"
    echo "  -g create <group>         Create new group"
    echo "  -g delete <group>         Delete group"
    echo ""
    echo "Password Policy:"
    echo "  --policy-enable           Enable password policy"
    echo "  --policy-disable          Disable password policy"
    echo "  --min-len <num>           Minimum password length (default: 12)"
    echo "  --max-days <num>          Maximum password age (default: 90)"
    echo ""
    echo "Other Options:"
    echo "  -l <file>       Log file (default: /var/log/user_manager.log)"
    echo "  -h              Show this help message"
    exit 1
}

# Parse command line arguments
ACTION=""
USERNAME=""
GROUP_ACTION=""
GROUP_NAME=""
TARGET_GROUP=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -a) ACTION="add"; USERNAME="$2"; shift 2 ;;
        -d) ACTION="delete"; USERNAME="$2"; shift 2 ;;
        -m) ACTION="modify"; USERNAME="$2"; shift 2 ;;
        -p) ACTION="passwd"; USERNAME="$2"; shift 2 ;;
        -l) ACTION="list"; shift ;;
        -i) ACTION="info"; USERNAME="$2"; shift 2 ;;
        -g) 
            GROUP_ACTION="$2"
            if [ "$GROUP_ACTION" = "add" ] || [ "$GROUP_ACTION" = "remove" ]; then
                USERNAME="$3"
                TARGET_GROUP="$4"
                shift 4
            elif [ "$GROUP_ACTION" = "list" ]; then
                USERNAME="$3"
                shift 3
            elif [ "$GROUP_ACTION" = "create" ]; then
                GROUP_NAME="$3"
                shift 3
            elif [ "$GROUP_ACTION" = "delete" ]; then
                GROUP_NAME="$3"
                shift 3
            fi
            ;;
        --policy-enable) PASSWORD_POLICY=true; shift ;;
        --policy-disable) PASSWORD_POLICY=false; shift ;;
        --min-len) MIN_PASS_LEN="$2"; shift 2 ;;
        --max-days) MAX_DAYS="$2"; shift 2 ;;
        -l) LOG_FILE="$2"; shift 2 ;;
        -h) usage ;;
        *) usage ;;
    esac
done

# Function to log messages
log_message() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Function to validate password strength
validate_password() {
    local password="$1"
    
    if [ ${#password} -lt $MIN_PASS_LEN ]; then
        echo -e "${RED}Password must be at least $MIN_PASS_LEN characters long${NC}"
        return 1
    fi
    
    if ! [[ "$password" =~ [A-Z] ]]; then
        echo -e "${RED}Password must contain at least one uppercase letter${NC}"
        return 1
    fi
    
    if ! [[ "$password" =~ [a-z] ]]; then
        echo -e "${RED}Password must contain at least one lowercase letter${NC}"
        return 1
    fi
    
    if ! [[ "$password" =~ [0-9] ]]; then
        echo -e "${RED}Password must contain at least one number${NC}"
        return 1
    fi
    
    if ! [[ "$password" =~ [!@#$%^&*] ]]; then
        echo -e "${YELLOW}Warning: Password should contain special characters${NC}"
    fi
    
    return 0
}

# Function to add user
add_user() {
    local username="$1"
    
    if id "$username" &>/dev/null; then
        log_message "${RED}✗ User $username already exists${NC}"
        return 1
    fi
    
    log_message "${GREEN}Adding user: $username${NC}"
    
    # Create user with home directory
    useradd -m -s /bin/bash "$username"
    
    # Set password
    echo -e "${YELLOW}Set password for $username:${NC}"
    passwd "$username"
    
    # Set password expiry
    chage -M $MAX_DAYS -W $WARN_DAYS "$username"
    
    # Create .ssh directory
    mkdir -p "/home/$username/.ssh"
    chmod 700 "/home/$username/.ssh"
    chown "$username:$username" "/home/$username/.ssh"
    
    log_message "${GREEN}✓ User $username created successfully${NC}"
}

# Function to delete user
delete_user() {
    local username="$1"
    
    if ! id "$username" &>/dev/null; then
        log_message "${RED}✗ User $username does not exist${NC}"
        return 1
    fi
    
    log_message "${RED}Deleting user: $username${NC}"
    echo -e "${YELLOW}Remove home directory? (y/n): ${NC}"
    read -r response
    
    if [ "$response" = "y" ]; then
        userdel -r "$username"
        log_message "${GREEN}✓ User $username and home directory deleted${NC}"
    else
        userdel "$username"
        log_message "${GREEN}✓ User $username deleted (home directory preserved)${NC}"
    fi
}

# Function to modify user
modify_user() {
    local username="$1"
    
    if ! id "$username" &>/dev/null; then
        log_message "${RED}✗ User $username does not exist${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Modifying user: $username${NC}"
    echo "1. Change shell"
    echo "2. Change home directory"
    echo "3. Change user ID"
    echo "4. Lock/unlock account"
    echo "5. Set account expiry"
    read -r choice
    
    case $choice in
        1)
            echo "Available shells:"
            cat /etc/shells
            echo -n "Enter new shell: "
            read -r shell
            chsh -s "$shell" "$username"
            log_message "${GREEN}✓ Shell changed to $shell${NC}"
            ;;
        2)
            echo -n "Enter new home directory: "
            read -r home
            usermod -d "$home" "$username"
            log_message "${GREEN}✓ Home directory changed to $home${NC}"
            ;;
        3)
            echo -n "Enter new UID: "
            read -r uid
            usermod -u "$uid" "$username"
            log_message "${GREEN}✓ UID changed to $uid${NC}"
            ;;
        4)
            if passwd -S "$username" | grep -q "LK"; then
                passwd -u "$username"
                log_message "${GREEN}✓ Account unlocked${NC}"
            else
                passwd -l "$username"
                log_message "${GREEN}✓ Account locked${NC}"
            fi
            ;;
        5)
            echo -n "Enter expiry date (YYYY-MM-DD): "
            read -r expiry
            usermod -e "$expiry" "$username"
            log_message "${GREEN}✓ Account expiry set to $expiry${NC}"
            ;;
    esac
}

# Function to change password
change_password() {
    local username="$1"
    
    if ! id "$username" &>/dev/null; then
        log_message "${RED}✗ User $username does not exist${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Changing password for $username${NC}"
    
    if [ "$PASSWORD_POLICY" = true ]; then
        while true; do
            echo -n "Enter new password: "
            read -s password
            echo
            echo -n "Confirm password: "
            read -s password2
            echo
            
            if [ "$password" != "$password2" ]; then
                echo -e "${RED}Passwords do not match${NC}"
                continue
            fi
            
            if validate_password "$password"; then
                echo "$username:$password" | chpasswd
                break
            fi
        done
    else
        passwd "$username"
    fi
    
    log_message "${GREEN}✓ Password changed for $username${NC}"
}

# Function to list users
list_users() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        SYSTEM USERS${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    echo -e "${GREEN}Regular users (UID >= 1000):${NC}"
    awk -F: '$3>=1000 && $3<65534 {printf "  %-15s UID: %-5s Home: %s\n", $1, $3, $6}' /etc/passwd
    
    echo ""
    echo -e "${YELLOW}System users (UID < 1000):${NC}"
    awk -F: '$3<1000 {printf "  %-15s UID: %-5s\n", $1, $3}' /etc/passwd | head -20
}

# Function to show user info
show_user_info() {
    local username="$1"
    
    if ! id "$username" &>/dev/null; then
        log_message "${RED}✗ User $username does not exist${NC}"
        return 1
    fi
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        USER INFORMATION: $username${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    echo -e "${GREEN}User ID:${NC} $(id -u "$username")"
    echo -e "${GREEN}Group ID:${NC} $(id -g "$username")"
    echo -e "${GREEN}Groups:${NC} $(id -Gn "$username")"
    echo -e "${GREEN}Home Directory:${NC} $(eval echo ~"$username")"
    echo -e "${GREEN}Shell:${NC} $(getent passwd "$username" | cut -d: -f7)"
    echo -e "${GREEN}Account Created:${NC} $(ls -ld /home/"$username" 2>/dev/null | awk '{print $6, $7, $8}')"
    echo -e "${GREEN}Password Status:${NC} $(passwd -S "$username" | awk '{print $2}')"
    echo -e "${GREEN}Account Expires:${NC} $(chage -l "$username" | grep "Account expires" | cut -d: -f2)"
}

# Group management functions
group_add_user() {
    local user="$1"
    local group="$2"
    
    if ! id "$user" &>/dev/null; then
        log_message "${RED}✗ User $user does not exist${NC}"
        return 1
    fi
    
    if ! getent group "$group" &>/dev/null; then
        log_message "${RED}✗ Group $group does not exist${NC}"
        return 1
    fi
    
    usermod -aG "$group" "$user"
    log_message "${GREEN}✓ User $user added to group $group${NC}"
}

group_remove_user() {
    local user="$1"
    local group="$2"
    
    gpasswd -d "$user" "$group"
    log_message "${GREEN}✓ User $user removed from group $group${NC}"
}

group_list_user() {
    local user="$1"
    
    echo -e "${GREEN}Groups for user $user:${NC}"
    groups "$user"
}

group_create() {
    local group="$1"
    
    if getent group "$group" &>/dev/null; then
        log_message "${RED}✗ Group $group already exists${NC}"
        return 1
    fi
    
    groupadd "$group"
    log_message "${GREEN}✓ Group $group created${NC}"
}

group_delete() {
    local group="$1"
    
    if ! getent group "$group" &>/dev/null; then
        log_message "${RED}✗ Group $group does not exist${NC}"
        return 1
    fi
    
    groupdel "$group"
    log_message "${GREEN}✓ Group $group deleted${NC}"
}

# Main execution
case $ACTION in
    add) add_user "$USERNAME" ;;
    delete) delete_user "$USERNAME" ;;
    modify) modify_user "$USERNAME" ;;
    passwd) change_password "$USERNAME" ;;
    list) list_users ;;
    info) show_user_info "$USERNAME" ;;
    *)
        if [ -n "$GROUP_ACTION" ]; then
            case $GROUP_ACTION in
                add) group_add_user "$USERNAME" "$TARGET_GROUP" ;;
                remove) group_remove_user "$USERNAME" "$TARGET_GROUP" ;;
                list) group_list_user "$USERNAME" ;;
                create) group_create "$GROUP_NAME" ;;
                delete) group_delete "$GROUP_NAME" ;;
                *) usage ;;
            esac
        else
            usage
        fi
        ;;
esac
