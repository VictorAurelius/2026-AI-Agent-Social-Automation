#!/bin/bash
# Check current branch before committing
# Usage: ./scripts/check-branch.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CURRENT_BRANCH=$(git branch --show-current)

echo "========================================"
echo "  Branch Check"
echo "========================================"
echo ""
echo "Current branch: $CURRENT_BRANCH"
echo ""

if [ "$CURRENT_BRANCH" = "main" ]; then
    echo -e "${RED}❌ ERROR: You are on 'main' branch!${NC}"
    echo ""
    echo "❌ Direct commits to main are NOT allowed."
    echo ""
    echo "Please create a feature branch:"
    echo "  git checkout -b feature/your-feature-name"
    echo "  git checkout -b bugfix/issue-description"
    echo "  git checkout -b docs/update-description"
    echo ""
    exit 1
else
    echo -e "${GREEN}✅ OK: You are on '$CURRENT_BRANCH' branch${NC}"
    echo ""
    echo "Safe to commit. Follow these steps:"
    echo "  1. git add <files>"
    echo "  2. git commit -m \"type(scope): message\""
    echo "  3. git push -u origin $CURRENT_BRANCH"
    echo "  4. gh pr create --title \"...\" --body \"...\""
    echo ""
fi
