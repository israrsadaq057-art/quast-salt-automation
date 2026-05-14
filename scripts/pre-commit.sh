#!/bin/bash
# /srv/salt/quast/scripts/pre-commit.sh
# Git pre-commit hook for local validation
# Network Engineer: Israr Sadaq
#
# Install with: ln -s ../../scripts/pre-commit.sh .git/hooks/pre-commit

echo "=========================================="
echo "🔧 Running pre-commit validation"
echo "=========================================="

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

FAILED=0

# ============================================================
# Check 1: YAML syntax
# ============================================================
echo -e "\n${YELLOW}📝 Checking YAML syntax...${NC}"
for file in $(git diff --cached --name-only --diff-filter=ACM | grep -E '\.sls$'); do
    if [ -f "$file" ]; then
        python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "  ${GREEN}✅ $file${NC}"
        else
            echo -e "  ${RED}❌ $file - YAML syntax error${NC}"
            FAILED=1
        fi
    fi
done

# ============================================================
# Check 2: Jinja2 syntax
# ============================================================
echo -e "\n${YELLOW}📝 Checking Jinja2 syntax...${NC}"
for file in $(git diff --cached --name-only --diff-filter=ACM | grep -E '\.j2$'); do
    if [ -f "$file" ]; then
        python3 -c "from jinja2 import Template; Template(open('$file').read())" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "  ${GREEN}✅ $file${NC}"
        else
            echo -e "  ${RED}❌ $file - Jinja2 syntax error${NC}"
            FAILED=1
        fi
    fi
done

# ============================================================
# Check 3: No hardcoded secrets
# ============================================================
echo -e "\n${YELLOW}🔒 Checking for hardcoded secrets...${NC}"
for file in $(git diff --cached --name-only --diff-filter=ACM | grep -E '\.sls$'); do
    if [ -f "$file" ]; then
        if grep -q "password.*=" "$file" && ! grep -q "pillar" "$file"; then
            echo -e "  ${RED}❌ $file - Possible hardcoded password${NC}"
            FAILED=1
        elif grep -q "secret" "$file" && ! grep -q "pillar" "$file"; then
            echo -e "  ${RED}❌ $file - Possible hardcoded secret${NC}"
            FAILED=1
        else
            echo -e "  ${GREEN}✅ $file${NC}"
        fi
    fi
done

# ============================================================
# Check 4: State ID format
# ============================================================
echo -e "\n${YELLOW}📋 Checking state ID format...${NC}"
for file in $(git diff --cached --name-only --diff-filter=ACM | grep -E '\.sls$' | grep -v top.sls); do
    if [ -f "$file" ]; then
        if head -1 "$file" | grep -qE '^[a-z_][a-z0-9_-]*:$'; then
            echo -e "  ${GREEN}✅ $file${NC}"
        else
            echo -e "  ${RED}❌ $file - Invalid state ID format (use lowercase_with_underscores:)${NC}"
            FAILED=1
        fi
    fi
done

# ============================================================
# Summary
# ============================================================
echo ""
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All pre-commit checks passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Pre-commit checks failed. Please fix errors before committing.${NC}"
    exit 1
fi
