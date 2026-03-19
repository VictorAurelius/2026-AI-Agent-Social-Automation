#!/bin/bash
# Security scan for common vulnerabilities
# Usage: ./scripts/test/test-security.sh
# Exit: 0 = no issues, 1 = issues found

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ISSUES=0

echo "========================================"
echo "  Security Scan"
echo "========================================"
echo ""

# Test 1: No hardcoded tokens/passwords
echo "  [1] Checking for hardcoded secrets..."
secrets_found=$(grep -rl --include="*.json" --include="*.md" --include="*.sh" --include="*.sql" \
  -E "(sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{36}|password\s*[:=]\s*[\"'][^\"']{8,})" \
  "$PROJECT_DIR" 2>/dev/null | grep -v node_modules | grep -v .git || true)

if [ -n "$secrets_found" ]; then
  echo -e "  ${RED}FOUND potential secrets in:${NC}"
  echo "$secrets_found" | while read f; do echo "    - $f"; done
  ((ISSUES++))
else
  echo -e "  ${GREEN}No hardcoded secrets found${NC}"
fi

# Test 2: .env not committed
echo "  [2] Checking .env not in git..."
if git ls-files --error-unmatch docker/.env 2>/dev/null; then
  echo -e "  ${RED}FAIL - docker/.env is tracked by git!${NC}"
  ((ISSUES++))
else
  echo -e "  ${GREEN}.env not tracked${NC}"
fi

# Test 3: .gitignore includes sensitive patterns
echo "  [3] Checking .gitignore coverage..."
gitignore="$PROJECT_DIR/.gitignore"
missing=""
for pattern in ".env" "*.pem" "*.key"; do
  if ! grep -q "$pattern" "$gitignore" 2>/dev/null; then
    missing="$missing $pattern"
  fi
done
if [ -n "$missing" ]; then
  echo -e "  ${YELLOW}WARN - .gitignore missing:$missing${NC}"
  ((ISSUES++))
else
  echo -e "  ${GREEN}.gitignore covers sensitive patterns${NC}"
fi

# Test 4: SQL injection in workflow queries
echo "  [4] Checking SQL injection patterns in workflows..."
vuln_queries=0
for file in "$PROJECT_DIR"/workflows/n8n/*.json; do
  # Find queries with direct interpolation but no escapeSql
  queries=$(jq -r '.. | .query? // empty' "$file" 2>/dev/null | grep -E "\{\{.*\}\}" || true)
  if [ -n "$queries" ]; then
    # Check if the workflow has escapeSql function
    has_escape=$(jq -r '.. | .jsCode? // empty' "$file" 2>/dev/null | grep -c "escapeSql" || true)
    query_count=$(echo "$queries" | wc -l)
    if [ "$has_escape" -eq 0 ] && [ "$query_count" -gt 0 ]; then
      basename_file=$(basename "$file")
      echo -e "  ${YELLOW}WARN - $basename_file: $query_count queries without escapeSql${NC}"
      ((vuln_queries++))
    fi
  fi
done
if [ "$vuln_queries" -eq 0 ]; then
  echo -e "  ${GREEN}No unprotected SQL interpolation found${NC}"
fi

# Test 5: Check for exposed ports
echo "  [5] Checking Docker port exposure..."
compose_file="$PROJECT_DIR/docker/docker-compose.yml"
if [ -f "$compose_file" ]; then
  exposed=$(grep -c "0.0.0.0:" "$compose_file" 2>/dev/null || echo 0)
  if [ "$exposed" -gt 0 ]; then
    echo -e "  ${YELLOW}WARN - $exposed ports exposed to 0.0.0.0${NC}"
  else
    echo -e "  ${GREEN}Ports bound to localhost only${NC}"
  fi
fi

echo ""
echo "========================================"
if [ $ISSUES -gt 0 ]; then
  echo -e "  ${YELLOW}$ISSUES potential issues found${NC}"
  exit 1
else
  echo -e "  ${GREEN}No security issues found${NC}"
  exit 0
fi
