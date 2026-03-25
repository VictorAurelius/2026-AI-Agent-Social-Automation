#!/bin/bash
# Run all validation and test scripts
# Usage: ./scripts/test/run-all-tests.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TOTAL=0
PASSED=0
FAILED=0

run_test() {
  local name="$1"
  local script="$2"

  ((TOTAL++))
  echo ""
  echo -e "${BLUE}━━━ $name ━━━${NC}"
  echo ""

  if bash "$script"; then
    ((PASSED++))
  else
    ((FAILED++))
    echo -e "${RED}  ^^^ TEST SUITE FAILED ^^^${NC}"
  fi
}

echo "========================================"
echo "  Running All Tests"
echo "  $(date)"
echo "========================================"

run_test "Workflow Validation" "$SCRIPT_DIR/validate-workflows.sh"
run_test "SQL Validation" "$SCRIPT_DIR/validate-sql.sh"
run_test "Security Scan" "$SCRIPT_DIR/test-security.sh"

echo ""
echo "========================================"
echo "  SUMMARY"
echo "========================================"
echo -e "  Total:  $TOTAL test suites"
echo -e "  ${GREEN}Passed: $PASSED${NC}"
echo -e "  ${RED}Failed: $FAILED${NC}"
echo "========================================"

if [ $FAILED -gt 0 ]; then
  echo -e "\n${RED}Some tests failed!${NC}"
  exit 1
else
  echo -e "\n${GREEN}All tests passed!${NC}"
  exit 0
fi
