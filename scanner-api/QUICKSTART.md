# TPC Ops Scanner API - Quick Start (5 Minutes)

Get the API running in under 5 minutes!

## Prerequisites

- Node.js 18+ installed
- Supabase account with bulk ticket tables

## Step 1: Install (30 seconds)

```bash
cd scanner-api
npm install
```

## Step 2: Configure (2 minutes)

### 2.1: Create .env file

```bash
cp .env.example .env
```

### 2.2: Fill in 3 critical values

Edit `.env` and set:

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
QR_SECRET_KEY=your_secret_key_from_main_system
```

**Where to find these:**
- **VITE_SUPABASE_URL**: Supabase Dashboard → Settings → API
- **SUPABASE_SERVICE_ROLE_KEY**: Supabase Dashboard → Settings → API (service_role key)
- **QR_SECRET_KEY**: From main Mounterra Vendor Portal .env file

## Step 3: Set Up Database (1 minute)

### 3.1: Copy SQL function

Open `database/verify_and_use_ticket.sql`

### 3.2: Run in Supabase

1. Go to Supabase Dashboard → SQL Editor
2. Paste the SQL
3. Click "Run"

## Step 4: Start Server (10 seconds)

```bash
npm run dev
```

## Step 5: Test (1 minute)

### 5.1: Health Check

```bash
curl http://localhost:3000/health
```

Should return:
```json
{"status":"ok","timestamp":"...","uptime":...}
```

### 5.2: Test Authentication

```bash
curl http://localhost:3000/api/scanner/scan-history \
  -H "Authorization: Bearer scanner_api_key_12345" \
  -H "X-Scanner-ID: test-scanner"
```

Should return:
```json
{"success":true,"scans":[],"total":0}
```

## ✅ Success!

Your Scanner API is running!

---

## Next Steps

### Test with Real Ticket

1. Get a ticket from Supabase:

```sql
SELECT ticket_number, qr_code_data, qr_code_signature
FROM bulk_tickets
WHERE is_valid = true AND is_used = false
LIMIT 1;
```

2. Generate test request:

```bash
node scripts/generate-test-signature.js
```

3. Copy and run the cURL command

---

## Troubleshooting

### ❌ "Missing Supabase configuration"

**Fix**: Check your .env file has VITE_SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY

### ❌ "Function verify_and_use_ticket does not exist"

**Fix**: Run `database/verify_and_use_ticket.sql` in Supabase SQL Editor

### ❌ "signature_mismatch" for valid tickets

**Fix**: Ensure QR_SECRET_KEY matches the main system exactly

---

## Deploy to Production

See [DEPLOYMENT.md](DEPLOYMENT.md) for:
- Vercel (easiest)
- Railway
- Render
- VPS
- Docker

---

## Documentation

- **Full API Docs**: [README.md](README.md)
- **Complete Setup**: [SETUP.md](SETUP.md)
- **Mobile Integration**: [INTEGRATION.md](INTEGRATION.md)
- **Project Overview**: [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)

---

**That's it! You're ready to scan tickets. 🎫**
