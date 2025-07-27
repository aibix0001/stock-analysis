#!/bin/bash
# Validate Stock Analysis LXC template

set -euo pipefail

# Configuration
TEMPLATE_FILE="${1:-}"
TEMP_DIR="/tmp/lxc-template-validate-$$"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Cleanup
cleanup() {
    rm -rf "${TEMP_DIR}"
}
trap cleanup EXIT

# Usage
if [ -z "${TEMPLATE_FILE}" ]; then
    echo "Usage: $0 <template-file.tar.gz>"
    exit 1
fi

# Check if template exists
if [ ! -f "${TEMPLATE_FILE}" ]; then
    echo -e "${RED}Error: Template file not found: ${TEMPLATE_FILE}${NC}"
    exit 1
fi

echo -e "${BLUE}Validating LXC Template: ${TEMPLATE_FILE}${NC}"
echo "=============================================="

# Create temp directory
mkdir -p "${TEMP_DIR}"

# Extract template
echo -e "${BLUE}Extracting template...${NC}"
if tar -xzf "${TEMPLATE_FILE}" -C "${TEMP_DIR}"; then
    echo -e "${GREEN}✓ Template extracted successfully${NC}"
else
    echo -e "${RED}✗ Failed to extract template${NC}"
    exit 1
fi

# Validation counters
ERRORS=0
WARNINGS=0

# Function to check file/directory
check_exists() {
    local path="$1"
    local type="$2"
    local required="${3:-yes}"
    
    if [ -e "${TEMP_DIR}/${path}" ]; then
        echo -e "${GREEN}✓ ${type}: ${path}${NC}"
        return 0
    else
        if [ "${required}" = "yes" ]; then
            echo -e "${RED}✗ Missing ${type}: ${path}${NC}"
            ((ERRORS++))
        else
            echo -e "${YELLOW}⚠ Optional ${type} missing: ${path}${NC}"
            ((WARNINGS++))
        fi
        return 1
    fi
}

# Function to check file content
check_content() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    
    if grep -q "${pattern}" "${TEMP_DIR}/${file}" 2>/dev/null; then
        echo -e "${GREEN}✓ ${description}${NC}"
        return 0
    else
        echo -e "${RED}✗ ${description} not found in ${file}${NC}"
        ((ERRORS++))
        return 1
    fi
}

echo ""
echo -e "${BLUE}Checking template structure...${NC}"

# Check required directories
check_exists "rootfs" "directory"
check_exists "rootfs/etc" "directory"
check_exists "rootfs/opt" "directory"
check_exists "rootfs/var" "directory"
check_exists "template-info" "file"

echo ""
echo -e "${BLUE}Checking system files...${NC}"

# Check system configuration
check_exists "rootfs/etc/hostname" "file"
check_exists "rootfs/etc/hosts" "file"
check_exists "rootfs/etc/network/interfaces" "file"
check_exists "rootfs/etc/apt/sources.list" "file"

echo ""
echo -e "${BLUE}Checking application files...${NC}"

# Check stock-analysis installation
check_exists "rootfs/opt/stock-analysis" "directory"
check_exists "rootfs/opt/stock-analysis/scripts" "directory"
check_exists "rootfs/opt/stock-analysis/services" "directory"
check_exists "rootfs/opt/stock-analysis/shared" "directory"
check_exists "rootfs/opt/stock-analysis/tests" "directory"

# Check important scripts
check_exists "rootfs/opt/stock-analysis/scripts/first-boot.sh" "script"
check_exists "rootfs/opt/stock-analysis/scripts/setup-python-env.sh" "script"
check_exists "rootfs/opt/stock-analysis/scripts/create-systemd-service.sh" "script"

# Check shared modules
check_exists "rootfs/opt/stock-analysis/shared/health_check.py" "module"
check_exists "rootfs/opt/stock-analysis/shared/database/event-store-schema.sql" "schema"

echo ""
echo -e "${BLUE}Checking service configurations...${NC}"

# Check systemd services
check_exists "rootfs/etc/systemd/system/stock-analysis-firstboot.service" "service"

# Check database configurations
check_exists "rootfs/etc/postgresql" "directory" "no"
check_exists "rootfs/etc/redis/redis.conf" "config"

echo ""
echo -e "${BLUE}Checking template metadata...${NC}"

# Validate template-info
if [ -f "${TEMP_DIR}/template-info" ]; then
    # Check required fields
    check_content "template-info" "^NAME:" "Template name"
    check_content "template-info" "^VERSION:" "Template version"
    check_content "template-info" "^OS:" "Operating system"
    check_content "template-info" "^ARCH:" "Architecture"
    check_content "template-info" "^MIN_RAM:" "Minimum RAM"
    check_content "template-info" "^MIN_DISK:" "Minimum disk"
    
    # Display template info
    echo ""
    echo -e "${BLUE}Template Information:${NC}"
    grep "^NAME:" "${TEMP_DIR}/template-info" | sed 's/^/  /'
    grep "^VERSION:" "${TEMP_DIR}/template-info" | sed 's/^/  /'
    grep "^OS:" "${TEMP_DIR}/template-info" | sed 's/^/  /'
    grep "^BUILD_DATE:" "${TEMP_DIR}/template-info" | sed 's/^/  /'
fi

echo ""
echo -e "${BLUE}Checking permissions...${NC}"

# Check executable permissions
for script in $(find "${TEMP_DIR}/rootfs/opt/stock-analysis/scripts" -name "*.sh" 2>/dev/null); do
    if [ -x "${script}" ]; then
        echo -e "${GREEN}✓ Executable: ${script#${TEMP_DIR}/rootfs/}${NC}"
    else
        echo -e "${YELLOW}⚠ Not executable: ${script#${TEMP_DIR}/rootfs/}${NC}"
        ((WARNINGS++))
    fi
done

echo ""
echo -e "${BLUE}Checking user configuration...${NC}"

# Check if stock-analysis user exists
if grep -q "^stock-analysis:" "${TEMP_DIR}/rootfs/etc/passwd" 2>/dev/null; then
    echo -e "${GREEN}✓ User 'stock-analysis' exists${NC}"
else
    echo -e "${RED}✗ User 'stock-analysis' not found${NC}"
    ((ERRORS++))
fi

# Check sudo configuration
check_exists "rootfs/etc/sudoers.d/stock-analysis" "file"

echo ""
echo -e "${BLUE}Performing size analysis...${NC}"

# Calculate sizes
TOTAL_SIZE=$(du -sh "${TEMP_DIR}" 2>/dev/null | cut -f1)
ROOTFS_SIZE=$(du -sh "${TEMP_DIR}/rootfs" 2>/dev/null | cut -f1)
APP_SIZE=$(du -sh "${TEMP_DIR}/rootfs/opt/stock-analysis" 2>/dev/null | cut -f1)

echo "  Total extracted size: ${TOTAL_SIZE}"
echo "  Rootfs size: ${ROOTFS_SIZE}"
echo "  Application size: ${APP_SIZE}"

# Check if size is reasonable
ROOTFS_SIZE_MB=$(du -sm "${TEMP_DIR}/rootfs" 2>/dev/null | cut -f1)
if [ "${ROOTFS_SIZE_MB}" -gt 2048 ]; then
    echo -e "${YELLOW}⚠ Warning: Rootfs is larger than 2GB (${ROOTFS_SIZE_MB}MB)${NC}"
    ((WARNINGS++))
fi

echo ""
echo -e "${BLUE}Checking for common issues...${NC}"

# Check for .git directories
if find "${TEMP_DIR}/rootfs" -name ".git" -type d 2>/dev/null | grep -q .; then
    echo -e "${YELLOW}⚠ Warning: .git directories found in template${NC}"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓ No .git directories${NC}"
fi

# Check for __pycache__ directories
if find "${TEMP_DIR}/rootfs" -name "__pycache__" -type d 2>/dev/null | grep -q .; then
    echo -e "${YELLOW}⚠ Warning: __pycache__ directories found${NC}"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓ No __pycache__ directories${NC}"
fi

# Check for large log files
LARGE_LOGS=$(find "${TEMP_DIR}/rootfs/var/log" -type f -size +1M 2>/dev/null || true)
if [ -n "${LARGE_LOGS}" ]; then
    echo -e "${YELLOW}⚠ Warning: Large log files found${NC}"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓ No large log files${NC}"
fi

# Summary
echo ""
echo "=============================================="
echo -e "${BLUE}Validation Summary${NC}"
echo "=============================================="

if [ ${ERRORS} -eq 0 ]; then
    if [ ${WARNINGS} -eq 0 ]; then
        echo -e "${GREEN}✅ Template validation PASSED${NC}"
        echo "   No errors or warnings found"
        EXIT_CODE=0
    else
        echo -e "${YELLOW}⚠️  Template validation PASSED with warnings${NC}"
        echo "   Errors: 0"
        echo "   Warnings: ${WARNINGS}"
        EXIT_CODE=0
    fi
else
    echo -e "${RED}❌ Template validation FAILED${NC}"
    echo "   Errors: ${ERRORS}"
    echo "   Warnings: ${WARNINGS}"
    EXIT_CODE=1
fi

echo ""
echo "Template file: ${TEMPLATE_FILE}"
echo "Template size: $(du -h "${TEMPLATE_FILE}" | cut -f1)"

exit ${EXIT_CODE}