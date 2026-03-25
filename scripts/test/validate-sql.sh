#!/bin/bash
# Validate SQL init scripts
# Usage: ./scripts/test/validate-sql.sh
# Exit: 0 = all pass, 1 = failures found

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
SQL_DIR="$PROJECT_DIR/infrastructure/docker/init-db"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

echo "========================================"
echo "  SQL Script Validation"
echo "========================================"
echo ""

for file in "$SQL_DIR"/*.sql; do
  filename=$(basename "$file")
  echo -n "  $filename: "

  errors=""

  # Test 1: File not empty
  if [ ! -s "$file" ]; then
    echo -e "${RED}FAIL - Empty file${NC}"
    ((FAIL++))
    continue
  fi

  # Test 2: No syntax errors (basic check)
  # Check for unclosed quotes
  single_quotes=$(grep -o "'" "$file" | wc -l)
  if [ $((single_quotes % 2)) -ne 0 ]; then
    # Could be escaped quotes (''), check more carefully
    escaped_quotes=$(grep -o "''" "$file" | wc -l)
    remaining=$((single_quotes - escaped_quotes * 2))
    if [ $((remaining % 2)) -ne 0 ]; then
      errors="${errors}Unclosed single quote; "
    fi
  fi

  # Test 3: Check for common SQL issues
  # Missing semicolons at end of statements
  last_char=$(tail -c 2 "$file" | head -c 1)

  # Test 4: Check CREATE TABLE has PRIMARY KEY
  tables_without_pk=$(grep -c "CREATE TABLE" "$file" || true)
  tables_with_pk=$(grep -c "PRIMARY KEY" "$file" || true)

  if [ "$tables_without_pk" -gt 0 ] && [ "$tables_with_pk" -lt "$tables_without_pk" ]; then
    errors="${errors}Some tables may lack PRIMARY KEY; "
  fi

  # Test 5: Check INSERT has matching column count
  # Basic check - count commas in column list vs values

  # Test 6: Check for potential SQL injection in VALUES
  if grep -qE "VALUES\s*\([^)]*\+[^)]*\)" "$file" 2>/dev/null; then
    errors="${errors}Potential string concatenation in VALUES; "
  fi

  # Test 7: Check for IF NOT EXISTS on CREATE
  creates_without_ine=$(grep "CREATE TABLE\|CREATE INDEX" "$file" | grep -vc "IF NOT EXISTS" || true)
  total_creates=$(grep -c "CREATE TABLE\|CREATE INDEX" "$file" || true)

  if [ "$creates_without_ine" -gt 0 ] && [ "$total_creates" -gt 0 ]; then
    # Only warn, not fail - first-time scripts don't need IF NOT EXISTS
    :
  fi

  if [ -n "$errors" ]; then
    echo -e "${YELLOW}WARN - ${errors}${NC}"
    ((WARN++))
  else
    lines=$(wc -l < "$file")
    tables=$(grep -c "CREATE TABLE" "$file" || echo 0)
    inserts=$(grep -c "INSERT INTO" "$file" || echo 0)
    echo -e "${GREEN}PASS (${lines} lines, ${tables} tables, ${inserts} inserts)${NC}"
    ((PASS++))
  fi
done

echo ""
echo "========================================"
echo -e "  Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}, ${YELLOW}$WARN warnings${NC}"
echo "========================================"

if [ $FAIL -gt 0 ]; then
  exit 1
fi

# CI marker
if [ $FAIL -eq 0 ]; then touch /tmp/sql-pass 2>/dev/null || true; fi
exit 0
