#!/bin/bash
# Script to test and verify all tasks in the system security playbook

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to check if a test passed
check_test() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}[PASS]${NC} $2"
        return 0
    else
        echo -e "${RED}[FAIL]${NC} $2"
        return 1
    fi
}

# Check if domain argument is provided
if [ -z "$1" ]; then
    echo -e "${YELLOW}Warning: No domain provided. Let's Encrypt verification will be skipped.${NC}"
    echo "Usage: $0 [domain-name]"
    DOMAIN="example.com"
else
    DOMAIN="$1"
    echo "Using domain: $DOMAIN"
fi

# Run the Ansible playbook
echo "============================================="
echo "Running Ansible playbook..."
echo "============================================="
ansible-playbook -i inventory system-security-playbook.yml -e "domain=$DOMAIN" -v

echo ""
echo "============================================="
echo "Verifying results..."
echo "============================================="

# Test SSH configuration
echo -e "\n${YELLOW}Testing SSH configuration...${NC}"
ssh_port=$(grep "Port " /etc/ssh/sshd_config | grep -v "^#" | awk '{print $2}')
check_test "$([ "$ssh_port" == "2222" ]; echo $?)" "SSH port changed to 2222"

passwd_auth=$(grep "PasswordAuthentication " /etc/ssh/sshd_config | grep -v "^#" | awk '{print $2}')
check_test "$([ "$passwd_auth" == "no" ]; echo $?)" "Password authentication disabled"

pubkey_auth=$(grep "PubkeyAuthentication " /etc/ssh/sshd_config | grep -v "^#" | awk '{print $2}')
check_test "$([ "$pubkey_auth" == "yes" ]; echo $?)" "Key-based authentication enabled"

# Test firewall configuration
echo -e "\n${YELLOW}Testing firewall configuration...${NC}"
ufw_status=$(ufw status | grep "Status: ")
check_test "$([ "$ufw_status" == "Status: active" ]; echo $?)" "Firewall is active"

http_rule=$(ufw status | grep "80/tcp" | grep "DENY")
check_test "$([ ! -z "$http_rule" ]; echo $?)" "HTTP (port 80) blocked"

https_rule=$(ufw status | grep "443/tcp" | grep "ALLOW")
check_test "$([ ! -z "$https_rule" ]; echo $?)" "HTTPS (port 443) allowed"

ssh_rule=$(ufw status | grep "2222/tcp" | grep "ALLOW")
check_test "$([ ! -z "$ssh_rule" ]; echo $?)" "SSH custom port (2222) allowed"

# Test file permissions
echo -e "\n${YELLOW}Testing file permissions...${NC}"
root_perms=$(stat -c "%a" /)
check_test "$([ "$root_perms" == "700" ]; echo $?)" "Root directory permissions (700)"

shadow_perms=$(stat -c "%a" /etc/shadow)
check_test "$([ "$shadow_perms" == "600" ]; echo $?)" "Shadow file permissions (600)"

# Test user limits
echo -e "\n${YELLOW}Testing user limits...${NC}"
user_exists=$(id test_user > /dev/null 2>&1; echo $?)
check_test "$user_exists" "test_user account exists"

limits_set=$(grep "test_user hard nofile 3" /etc/security/limits.conf > /dev/null 2>&1; echo $?)
check_test "$limits_set" "File limits configured in limits.conf"

# Test application installation
echo -e "\n${YELLOW}Testing application installation...${NC}"
nginx_installed=$(command -v nginx > /dev/null 2>&1; echo $?)
check_test "$nginx_installed" "nginx installed"

curl_installed=$(command -v curl > /dev/null 2>&1; echo $?)
check_test "$curl_installed" "curl installed"

nginx_running=$(systemctl is-active nginx > /dev/null 2>&1; echo $?)
check_test "$nginx_running" "nginx service running"

# Test HTTP request
http_response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)
check_test "$([ "$http_response" == "200" ]; echo $?)" "HTTP request successful (200 OK)"

# Test Let's Encrypt (if domain was provided and not example.com)
if [ "$DOMAIN" != "example.com" ]; then
    echo -e "\n${YELLOW}Testing Let's Encrypt configuration...${NC}"
    cert_exists=$(ls -la /etc/letsencrypt/live/$DOMAIN/fullchain.pem 2>/dev/null)
    cert_status=$?
    check_test "$([ $cert_status -eq 0 ]; echo $?)" "Let's Encrypt certificate exists"
    
    if [ $cert_status -eq 0 ]; then
        https_response=$(curl -s -o /dev/null -w "%{http_code}" -k https://localhost)
        check_test "$([ "$https_response" == "200" ]; echo $?)" "HTTPS request successful (200 OK)"
    else
        echo -e "${YELLOW}Skipping HTTPS test as certificate was not found${NC}"
    fi
else
    echo -e "\n${YELLOW}Skipping Let's Encrypt verification (using example domain)${NC}"
fi

echo -e "\n${GREEN}Verification completed${NC}"