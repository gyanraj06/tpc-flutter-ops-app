#!/bin/bash

# Test script for Scanner API endpoints
# Usage: ./scripts/test-api.sh

BASE_URL="http://localhost:3000"
SCANNER_API_KEY="scanner_api_key_12345"
SCANNER_ID="test-scanner-01"

echo "=== TPC Ops Scanner API Test Suite ==="
echo ""

# Test 1: Health Check
echo "1. Testing Health Check..."
curl -s "$BASE_URL/health" | jq '.'
echo ""

# Test 2: API Info
echo "2. Testing API Info..."
curl -s "$BASE_URL/api" | jq '.'
echo ""

# Test 3: Verify and Scan (should fail without proper QR data)
echo "3. Testing Verify and Scan (invalid request)..."
curl -s -X POST "$BASE_URL/api/scanner/verify-and-scan" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SCANNER_API_KEY" \
  -H "X-Scanner-ID: $SCANNER_ID" \
  -d '{}' | jq '.'
echo ""

# Test 4: Get Ticket Details (should fail - ticket not found)
echo "4. Testing Get Ticket Details (not found)..."
curl -s "$BASE_URL/api/scanner/ticket-details?ticketNumber=INVALID" \
  -H "Authorization: Bearer $SCANNER_API_KEY" \
  -H "X-Scanner-ID: $SCANNER_ID" | jq '.'
echo ""

# Test 5: Get Scan History
echo "5. Testing Get Scan History..."
curl -s "$BASE_URL/api/scanner/scan-history?limit=5" \
  -H "Authorization: Bearer $SCANNER_API_KEY" \
  -H "X-Scanner-ID: $SCANNER_ID" | jq '.'
echo ""

# Test 6: Unauthorized Request (no API key)
echo "6. Testing Unauthorized Request..."
curl -s "$BASE_URL/api/scanner/scan-history" \
  -H "X-Scanner-ID: $SCANNER_ID" | jq '.'
echo ""

echo "=== Test Suite Complete ==="
