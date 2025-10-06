#!/bin/bash
# Build all language versions of the BIOS Introduction book

set -e  # Exit on error

echo "🚀 Building BIOS Introduction - All Languages"
echo "=============================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Build Japanese version (original)
echo -e "${BLUE}📚 Building Japanese version...${NC}"
mdbook build
echo -e "${GREEN}✓ Japanese version built successfully${NC}"
echo ""

# Build English version
echo -e "${BLUE}📚 Building English version...${NC}"
MDBOOK_BOOK__LANGUAGE=en mdbook build -d book/en
echo -e "${GREEN}✓ English version built successfully${NC}"
echo ""

# Summary
echo "=============================================="
echo -e "${GREEN}✅ All language versions built successfully!${NC}"
echo ""
echo "Output locations:"
echo "  Japanese: book/"
echo "  English:  book/en/"
echo ""
echo "To preview locally:"
echo "  mdbook serve"
echo "  Then visit:"
echo "    Japanese: http://localhost:3000/"
echo "    English:  http://localhost:3000/en/"
