# TPC Ops Scanner API

Backend API for the TPC Ops QR code ticket scanner mobile application. This API handles ticket verification, entry management, and scan logging for the Mounterra Vendor Portal bulk ticket system.

## Features

- **QR Code Verification**: HMAC-SHA256 signature verification to prevent forgery
- **Ticket Validation**: Real-time ticket status checking (valid/invalid, used/unused)
- **Entry Management**: Atomic ticket marking with concurrent scan protection
- **Audit Logging**: Complete scan history with timestamps and scanner info
- **Statistics**: Real-time event statistics and scan analytics
- **Security**: API key authentication, rate limiting, and row-level locking

## Quick Start

### Prerequisites

- Node.js 18+ and npm
- Supabase account with bulk ticket tables configured
- QR_SECRET_KEY from main ticket generation system

### Installation

```bash
cd scanner-api
npm install
```

### Configuration

1. Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

2. Configure environment variables:

```env
# Supabase Configuration
VITE_SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# QR Code Security (MUST match key from main system)
QR_SECRET_KEY=your_secret_key_here

# Scanner API Configuration
SCANNER_API_KEY=scanner_api_key_12345
ADMIN_API_KEY=admin_api_key_67890

# Server Configuration
PORT=3000
NODE_ENV=development
```

3. Set up PostgreSQL function in Supabase:

Run the SQL script in `database/verify_and_use_ticket.sql` in your Supabase SQL editor.

### Running the Server

**Development mode:**

```bash
npm run dev
```

**Production mode:**

```bash
npm run build
npm start
```

### Health Check

```bash
curl http://localhost:3000/health
```

## API Endpoints

### Authentication

All endpoints require authentication via:

**Headers:**
```
Authorization: Bearer <SCANNER_API_KEY>
X-Scanner-ID: <unique-scanner-id>
X-Scanner-Name: <optional-scanner-name>
```

Admin endpoints require:
```
Authorization: Bearer <ADMIN_API_KEY>
```

---

### 1. Verify and Scan Ticket

**POST** `/api/scanner/verify-and-scan`

Primary endpoint for entry scanning - verifies QR code and marks ticket as used.

**Request:**

```json
{
  "qrData": "{\"ticketNumber\":\"MTK1001\",\"batchId\":\"550e8400\",\"customerName\":\"John Doe\",\"eventDate\":\"15/01/2026\"}",
  "signature": "abc123def456...",
  "scannerId": "scanner-01",
  "scannerName": "Gate 1 - Main Entrance",
  "location": "Himalayas Base Camp",
  "markAsUsed": true
}
```

**Response (Success - Allow Entry):**

```json
{
  "success": true,
  "result": "valid_unused",
  "message": "Ticket verified successfully - ALLOW ENTRY",
  "allowEntry": true,
  "ticket": {
    "ticketNumber": "MTK1001",
    "customerName": "John Doe",
    "email": "john@example.com",
    "phoneNumber": "+919876543210",
    "eventDate": "2026-01-15",
    "ticketPrice": 2500
  },
  "batch": {
    "eventTitle": "Mountain Trek Adventure 2026",
    "venue": "Himalayas Base Camp"
  },
  "scanTime": "2026-01-15T08:30:00.000Z"
}
```

**Response (Already Used):**

```json
{
  "success": true,
  "result": "already_used",
  "message": "Ticket has already been used",
  "allowEntry": false,
  "ticket": {
    "ticketNumber": "MTK1001",
    "customerName": "John Doe",
    "usedAt": "2026-01-15T08:15:00.000Z"
  },
  "scanTime": "2026-01-15T08:30:00.000Z"
}
```

**Result Codes:**

| Code | Allow Entry | Description |
|------|-------------|-------------|
| `valid_unused` | ✅ YES | Valid ticket, not used - ALLOW ENTRY |
| `already_used` | ❌ NO | Already scanned |
| `invalid` | ❌ NO | Invalidated by vendor |
| `not_found` | ❌ NO | Ticket doesn't exist |
| `signature_mismatch` | ❌ NO | Forged QR code |

---

### 2. Verify Only (Preview Mode)

**POST** `/api/scanner/verify-only`

Verify ticket WITHOUT marking as used. Same request/response format as verify-and-scan.

---

### 3. Get Ticket Details

**GET** `/api/scanner/ticket-details?ticketNumber=MTK1001`

Fetch complete ticket information including scan history.

**Response:**

```json
{
  "success": true,
  "ticket": {
    "id": "770e8400-e29b-41d4-a716-446655440001",
    "ticketNumber": "MTK1001",
    "customerName": "John Doe",
    "email": "john@example.com",
    "phoneNumber": "+919876543210",
    "eventDate": "2026-01-15",
    "ticketPrice": 2500,
    "isValid": true,
    "isUsed": false,
    "usedAt": null,
    "pdfUrl": "https://..."
  },
  "batch": {
    "eventTitle": "Mountain Trek Adventure 2026",
    "venue": "Himalayas Base Camp",
    "primaryColor": "#3b82f6",
    "secondaryColor": "#10b981",
    "accentColor": "#f59e0b"
  },
  "scanHistory": [
    {
      "scannedAt": "2026-01-15T08:30:00.000Z",
      "scannedBy": "Gate 1",
      "scanResult": "success"
    }
  ]
}
```

---

### 4. Get Scan History

**GET** `/api/scanner/scan-history`

Fetch scan history with optional filters.

**Query Parameters:**

- `scannerId` (optional): Filter by scanner device
- `batchId` (optional): Filter by event batch
- `limit` (optional): Results per page (default: 50)
- `offset` (optional): Pagination offset (default: 0)
- `from` (optional): Start date (ISO 8601)
- `to` (optional): End date (ISO 8601)

**Example:**

```
GET /api/scanner/scan-history?scannerId=scanner-01&limit=20
```

**Response:**

```json
{
  "success": true,
  "scans": [
    {
      "id": "990e8400-...",
      "ticketNumber": "MTK1001",
      "customerName": "John Doe",
      "scanResult": "success",
      "scannedBy": "Gate 1",
      "scannedAt": "2026-01-15T08:30:00.000Z",
      "scanNotes": "Scanned at Himalayas Base Camp"
    }
  ],
  "total": 48,
  "page": 1,
  "limit": 20
}
```

---

### 5. Get Batch Statistics

**GET** `/api/scanner/batch-stats?batchId=550e8400`

Get real-time statistics for an event.

**Response:**

```json
{
  "success": true,
  "batchId": "550e8400-...",
  "eventTitle": "Mountain Trek Adventure 2026",
  "venue": "Himalayas Base Camp",
  "stats": {
    "totalTickets": 100,
    "ticketsUsed": 48,
    "ticketsRemaining": 52,
    "ticketsInvalid": 2,
    "usagePercentage": 48,
    "lastScanTime": "2026-01-15T09:45:00.000Z"
  }
}
```

---

### 6. Manual Entry (Admin)

**POST** `/api/scanner/manual-entry`

Manually mark ticket as used (for damaged QR codes).

**Request:**

```json
{
  "ticketNumber": "MTK1001",
  "scannerId": "scanner-01",
  "scannerName": "Gate 1",
  "reason": "QR code damaged - verified via customer ID"
}
```

**Response:**

```json
{
  "success": true,
  "message": "Ticket marked as used manually",
  "ticket": {
    "ticketNumber": "MTK1001",
    "customerName": "John Doe",
    "usedAt": "2026-01-15T08:30:00.000Z"
  },
  "timestamp": "2026-01-15T08:30:00.000Z"
}
```

---

### 7. Undo Scan (Admin Only)

**POST** `/api/scanner/undo-scan`

Undo a ticket scan (mark as unused). Requires admin authentication.

**Request:**

```json
{
  "ticketNumber": "MTK1001",
  "adminId": "admin-123",
  "reason": "Scanned wrong ticket by mistake"
}
```

**Response:**

```json
{
  "success": true,
  "message": "Ticket scan undone successfully",
  "ticket": {
    "ticketNumber": "MTK1001",
    "customerName": "John Doe",
    "isUsed": false,
    "usedAt": null
  },
  "timestamp": "2026-01-15T08:35:00.000Z"
}
```

---

## Rate Limits

| Endpoint Type | Limit | Window |
|--------------|-------|--------|
| Verify endpoints | 100 requests | 1 minute |
| History/stats | 20 requests | 1 minute |
| Admin operations | 10 requests | 1 minute |

Rate limits are per scanner/IP address. Disabled in development mode.

---

## Error Handling

All errors return consistent format:

```json
{
  "success": false,
  "error": "error_code",
  "message": "Human-readable error message",
  "details": "Additional details (dev mode only)",
  "timestamp": "2026-01-15T08:30:00.000Z"
}
```

**Error Codes:**

- `unauthorized` (401): Invalid API key
- `forbidden` (403): Admin access required
- `not_found` (404): Resource not found
- `invalid_request` (400): Missing/invalid parameters
- `rate_limit_exceeded` (429): Too many requests
- `database_error` (500): Database connection failed
- `signature_mismatch`: QR code forgery detected
- `internal_server_error` (500): Unexpected error

---

## Security Features

### 1. HMAC Signature Verification

All QR codes are verified using timing-safe HMAC-SHA256 comparison:

```typescript
crypto.timingSafeEqual(expectedSignature, receivedSignature)
```

### 2. Concurrent Scan Protection

PostgreSQL row-level locking prevents duplicate entries:

```sql
SELECT * FROM bulk_tickets WHERE ticket_number = 'MTK1001' FOR UPDATE;
```

### 3. Authentication

- Scanner endpoints: API key + Scanner ID
- Admin endpoints: Separate admin API key
- Rate limiting per scanner/IP

### 4. Audit Trail

Every scan attempt (success or failure) is logged with:
- Timestamp
- Scanner ID
- Ticket number
- Result
- Location/notes

---

## Testing

### Test with cURL

**1. Health Check:**

```bash
curl http://localhost:3000/health
```

**2. Verify and Scan:**

```bash
curl -X POST http://localhost:3000/api/scanner/verify-and-scan \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer scanner_api_key_12345" \
  -H "X-Scanner-ID: scanner-01" \
  -H "X-Scanner-Name: Test Scanner" \
  -d '{
    "qrData": "{\"ticketNumber\":\"MTK1001\",\"batchId\":\"550e8400\",\"customerName\":\"John Doe\",\"eventDate\":\"15/01/2026\"}",
    "signature": "your_hmac_signature_here",
    "location": "Test Location",
    "markAsUsed": false
  }'
```

**3. Get Ticket Details:**

```bash
curl "http://localhost:3000/api/scanner/ticket-details?ticketNumber=MTK1001" \
  -H "Authorization: Bearer scanner_api_key_12345" \
  -H "X-Scanner-ID: scanner-01"
```

### Generating Test Signatures

Use the provided utility script:

```bash
node scripts/generate-test-signature.js
```

---

## Deployment

### Option 1: Vercel Serverless Functions

1. Install Vercel CLI:

```bash
npm i -g vercel
```

2. Create `vercel.json`:

```json
{
  "version": 2,
  "builds": [
    {
      "src": "src/index.ts",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "src/index.ts"
    }
  ]
}
```

3. Deploy:

```bash
vercel --prod
```

### Option 2: Railway / Render

1. Connect your GitHub repository
2. Set environment variables in dashboard
3. Deploy automatically on push

### Option 3: VPS with PM2

1. Install PM2:

```bash
npm install -g pm2
```

2. Build and start:

```bash
npm run build
pm2 start dist/index.js --name tpc-scanner-api
pm2 save
pm2 startup
```

---

## Database Setup

Run this SQL in your Supabase SQL editor:

```sql
-- See database/verify_and_use_ticket.sql
```

This creates the `verify_and_use_ticket` function for concurrent-safe ticket marking.

---

## Performance Targets

- **Scan verification**: < 500ms
- **Ticket lookup**: < 300ms
- **History query**: < 1 second
- **Uptime**: > 99.9% during events

---

## Monitoring

### Logs

Structured JSON logs with levels: INFO, WARN, ERROR, DEBUG

**Development:**
```bash
npm run dev
```

**Production (PM2):**
```bash
pm2 logs tpc-scanner-api
```

### Health Monitoring

Set up uptime monitoring on `/health` endpoint using:
- Uptime Robot
- Better Uptime
- Pingdom

---

## Troubleshooting

### Issue: "Missing Supabase configuration"

**Solution:** Ensure `.env` has `VITE_SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY`

### Issue: "QR signature mismatch"

**Solution:** Verify `QR_SECRET_KEY` matches the key used in ticket generation system

### Issue: "Function verify_and_use_ticket does not exist"

**Solution:** Run `database/verify_and_use_ticket.sql` in Supabase SQL editor

### Issue: Rate limit errors in production

**Solution:** Increase `RATE_LIMIT_MAX_REQUESTS` or implement per-scanner limits

---

## Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

---

## License

MIT License - See LICENSE file for details

---

## Support

For issues or questions:

- GitHub Issues: [Create an issue]
- Email: support@trippechalo.in
- Documentation: [Full API docs]

---

## Version History

### v1.0.0 (Current)

- Initial release
- QR code verification with HMAC
- Ticket marking with concurrent protection
- Scan history and statistics
- Admin operations (manual entry, undo scan)
- Rate limiting and authentication
- Complete audit trail

---

**Built with ❤️ for TPC Ops**
