#!/bin/bash
# Validate n8n workflow JSON files
# Usage: ./scripts/test/validate-workflows.sh
# Exit: 0 = all pass, 1 = failures found

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
WORKFLOW_DIRS=(
  "$PROJECT_DIR/modules/social/workflows"
  "$PROJECT_DIR/modules/novel/workflows"
  "$PROJECT_DIR/workflows/n8n"
)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

echo "========================================"
echo "  Workflow JSON Validation"
echo "========================================"
echo ""

for WORKFLOW_DIR in "${WORKFLOW_DIRS[@]}"; do
  if [ ! -d "$WORKFLOW_DIR" ]; then continue; fi
  echo -e "${YELLOW}Directory: $WORKFLOW_DIR${NC}"
done

for WORKFLOW_DIR in "${WORKFLOW_DIRS[@]}"; do
for file in "$WORKFLOW_DIR"/*.json; do
  [ -f "$file" ] || continue
  filename=$(basename "$file")
  echo -n "  $filename: "

  # Test 1: Valid JSON
  if ! python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
    if ! jq empty "$file" 2>/dev/null; then
      echo -e "${RED}FAIL - Invalid JSON${NC}"
      ((FAIL++))
      continue
    fi
  fi

  # Test 2: Has required fields
  has_name=$(jq -r '.name // empty' "$file" 2>/dev/null)
  has_nodes=$(jq '.nodes | length' "$file" 2>/dev/null)
  has_connections=$(jq '.connections | length' "$file" 2>/dev/null)

  if [ -z "$has_name" ]; then
    echo -e "${RED}FAIL - Missing 'name' field${NC}"
    ((FAIL++))
    continue
  fi

  if [ "$has_nodes" = "0" ] || [ -z "$has_nodes" ]; then
    echo -e "${RED}FAIL - No nodes found${NC}"
    ((FAIL++))
    continue
  fi

  # Test 3: All nodes have id, name, type
  missing_fields=$(jq '[.nodes[] | select(.id == null or .name == null or .type == null)] | length' "$file" 2>/dev/null)
  if [ "$missing_fields" != "0" ]; then
    echo -e "${RED}FAIL - $missing_fields nodes missing id/name/type${NC}"
    ((FAIL++))
    continue
  fi

  # Test 4: Check connections reference existing nodes
  node_names=$(jq -r '.nodes[].name' "$file" 2>/dev/null | sort)
  conn_sources=$(jq -r '.connections | keys[]' "$file" 2>/dev/null | sort)
  conn_targets=$(jq -r '[.connections[][] | .[] | .[].node] | unique | .[]' "$file" 2>/dev/null | sort)

  orphan_sources=""
  for src in $conn_sources; do
    if ! echo "$node_names" | grep -qx "$src"; then
      orphan_sources="$orphan_sources $src"
    fi
  done

  orphan_targets=""
  for tgt in $conn_targets; do
    if ! echo "$node_names" | grep -qx "$tgt"; then
      orphan_targets="$orphan_targets $tgt"
    fi
  done

  if [ -n "$orphan_sources" ]; then
    echo -e "${YELLOW}WARN - Connection source not found:$orphan_sources${NC}"
    ((WARN++))
    continue
  fi

  if [ -n "$orphan_targets" ]; then
    echo -e "${YELLOW}WARN - Connection target not found:$orphan_targets${NC}"
    ((WARN++))
    continue
  fi

  # Test 5: Check for SQL injection patterns in queries
  sql_injection=$(jq -r '.. | .query? // empty' "$file" 2>/dev/null | grep -c "escapeSql\|\\$json\." 2>/dev/null || true)
  raw_interpolation=$(jq -r '.. | .query? // empty' "$file" 2>/dev/null | grep -cE "\{\{.*\$json\." 2>/dev/null || true)

  if [ "$raw_interpolation" -gt 0 ] && [ "$sql_injection" -eq 0 ]; then
    echo -e "${YELLOW}WARN - SQL interpolation without escapeSql ($raw_interpolation queries)${NC}"
    ((WARN++))
    continue
  fi

  echo -e "${GREEN}PASS ($has_nodes nodes, $has_connections connections)${NC}"
  ((PASS++))
done
done

echo ""
echo "========================================"
echo -e "  Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}, ${YELLOW}$WARN warnings${NC}"
echo "========================================"

if [ $FAIL -gt 0 ]; then
  exit 1
fi

# CI marker
if [ $FAIL -eq 0 ]; then touch /tmp/wf-pass 2>/dev/null || true; fi
exit 0
