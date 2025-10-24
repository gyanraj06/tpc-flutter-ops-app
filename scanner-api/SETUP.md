# TPC Ops Scanner API - Complete Setup Guide

Step-by-step guide to get the Scanner API up and running.

## Prerequisites

Before you begin, ensure you have:

- [x] Node.js 18+ installed
- [x] npm or yarn package manager
- [x] Supabase account with project created
- [x] Access to the main Mounterra Vendor Portal codebase (for QR_SECRET_KEY)
- [x] Code editor (VS Code recommended)

---

## Step 1: Clone and Install

```bash
# Navigate to project directory
cd scanner-api

# Install dependencies
npm install

# Verify installation
npm run type-check
```

---

## Step 2: Configure Supabase

### 2.1: Verify Database Tables

Ensure these tables exist in your Supabase database:

1. `bulk_ticket_batches`
2. `bulk_tickets`
3. `bulk_ticket_scans`
4. `bulk_ticket_generation_logs`

**To verify**, go to Supabase Dashboard → Table Editor

### 2.2: Install PostgreSQL Function

1. Open Supabase Dashboard → SQL Editor
2. Copy the contents of `database/verify_and_use_ticket.sql`
3. Execute the SQL query
4. Verify function was created:

```sql
SELECT proname FROM pg_proc WHERE proname = 'verify_and_use_ticket';
```

You should see one row returned.

### 2.3: Get Supabase Credentials

From your Supabase project settings:

1. Go to Settings → API
2. Copy **Project URL** (e.g., `https://abc123.supabase.co`)
3. Copy **service_role key** (NOT the anon key)

⚠️ **Important**: The `service_role` key bypasses Row Level Security. Keep it secret!

---

## Step 3: Get QR Secret Key

The `QR_SECRET_KEY` MUST match the key used in your main ticket generation system.

### Find the Key

**Option 1: From Main System .env**

```bash
# In your main Mounterra Vendor Portal codebase
grep QR_SECRET_KEY .env
```

**Option 2: From Vercel Environment Variables**

1. Go to Vercel Dashboard → Your Project
2. Settings → Environment Variables
3. Find `QR_SECRET_KEY`
4. Copy the value

**Option 3: Generate New Key (NOT RECOMMENDED)**

⚠️ Only do this if starting fresh and no QR codes exist yet:

```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

---

## Step 4: Create Environment File

```bash
# Copy example file
cp .env.example .env

# Edit with your values
nano .env
```

**Fill in your values:**

```env
# Supabase Configuration
VITE_SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# QR Code Security (CRITICAL: Must match main system)
QR_SECRET_KEY=your_64_character_hex_string_here

# Scanner API Configuration
SCANNER_API_KEY=scanner_api_key_12345
ADMIN_API_KEY=admin_api_key_67890

# Server Configuration
PORT=3000
NODE_ENV=development

# Rate Limiting
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=100
```

### Generate API Keys

**Scanner API Key:**

```bash
node -e "console.log('scanner_' + require('crypto').randomBytes(16).toString('hex'))"
```

**Admin API Key:**

```bash
node -e "console.log('admin_' + require('crypto').randomBytes(16).toString('hex'))"
```

---

## Step 5: Start Development Server

```bash
npm run dev
```

You should see:

```
[2026-01-15T08:00:00.000Z] [INFO] TPC Ops Scanner API started | Data: {"port":3000,"environment":"development","nodeVersion":"v18.17.0"}
```

---

## Step 6: Test the API

### 6.1: Health Check

```bash
curl http://localhost:3000/health
```

**Expected response:**

```json
{
  "status": "ok",
  "timestamp": "2026-01-15T08:00:00.000Z",
  "uptime": 10.5,
  "environment": "development"
}
```

### 6.2: Test Authentication

```bash
curl http://localhost:3000/api/scanner/scan-history \
  -H "Authorization: Bearer scanner_api_key_12345" \
  -H "X-Scanner-ID: test-scanner-01"
```

**Expected response:**

```json
{
  "success": true,
  "scans": [],
  "total": 0,
  "page": 1,
  "limit": 50
}
```

### 6.3: Test Unauthorized Access

```bash
curl http://localhost:3000/api/scanner/scan-history
```

**Expected response:**

```json
{
  "success": false,
  "error": "unauthorized",
  "message": "Invalid API key",
  "timestamp": "2026-01-15T08:00:00.000Z"
}
```

✅ If you got these responses, your API is working!

---

## Step 7: Test with Real Ticket

### 7.1: Get a Test Ticket

From your Supabase database:

```sql
SELECT ticket_number, qr_code_data, qr_code_signature
FROM bulk_tickets
WHERE is_valid = true AND is_used = false
LIMIT 1;
```

Copy the values.

### 7.2: Generate Test Request

Use the signature generator script:

```bash
node scripts/generate-test-signature.js
```

Enter your values when prompted.

### 7.3: Test Verification

Copy the cURL command from the script output and run it.

**Expected response (Allow Entry):**

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

### 7.4: Verify Ticket Was Marked as Used

```sql
SELECT is_used, used_at FROM bulk_tickets WHERE ticket_number = 'MTK1001';
```

Should show `is_used = true` and a timestamp.

### 7.5: Test Duplicate Scan

Run the same cURL command again.

**Expected response (Deny Entry):**

```json
{
  "success": true,
  "result": "already_used",
  "message": "Ticket has already been used",
  "allowEntry": false,
  "ticket": {
    "ticketNumber": "MTK1001",
    "customerName": "John Doe",
    "usedAt": "2026-01-15T08:30:00.000Z"
  },
  "scanTime": "2026-01-15T08:31:00.000Z"
}
```

✅ Perfect! The concurrent scan protection is working.

---

## Step 8: Verify Scan Logging

Check that scans are being logged:

```sql
SELECT * FROM bulk_ticket_scans ORDER BY scanned_at DESC LIMIT 10;
```

You should see entries for your test scans.

---

## Step 9: Test All Endpoints

Run the automated test script:

```bash
# Make script executable (Linux/Mac)
chmod +x scripts/test-api.sh

# Run tests
./scripts/test-api.sh
```

Or manually test each endpoint from the README.md examples.

---

## Troubleshooting

### Issue: "Missing Supabase configuration"

**Cause**: Environment variables not loaded

**Solution**:
```bash
# Verify .env file exists
ls -la .env

# Check values are set
cat .env | grep SUPABASE

# Restart server
npm run dev
```

### Issue: "Function verify_and_use_ticket does not exist"

**Cause**: PostgreSQL function not installed

**Solution**:
```sql
-- Run in Supabase SQL Editor
-- Copy from database/verify_and_use_ticket.sql
```

### Issue: "signature_mismatch" for valid tickets

**Cause**: QR_SECRET_KEY doesn't match main system

**Solution**:
1. Verify QR_SECRET_KEY in main system
2. Update scanner-api/.env with exact same key
3. Restart server

### Issue: "Cannot find module '@supabase/supabase-js'"

**Cause**: Dependencies not installed

**Solution**:
```bash
rm -rf node_modules package-lock.json
npm install
```

### Issue: Database connection timeout

**Cause**: Supabase project paused or network issue

**Solution**:
1. Check Supabase dashboard - project should be active
2. Verify SUPABASE_URL is correct
3. Check network/firewall settings

---

## Next Steps

Now that your API is running:

1. ✅ **Deploy to production** (see [DEPLOYMENT.md](DEPLOYMENT.md))
2. ✅ **Integrate with scanner app** (see [INTEGRATION.md](INTEGRATION.md))
3. ✅ **Set up monitoring** (Sentry, Uptime Robot)
4. ✅ **Configure backups** (Supabase auto-backup)
5. ✅ **Test with real event** (low-stakes test first)

---

## Development Workflow

### Making Changes

```bash
# Make code changes
vim src/routes/verify.ts

# TypeScript will auto-compile in dev mode
# Server will auto-restart (tsx watch)
```

### Running Tests (Future)

```bash
npm test
```

### Building for Production

```bash
npm run build

# Test production build locally
npm start
```

### Code Quality

```bash
# Type checking
npm run type-check

# Linting
npm run lint
```

---

## Environment-Specific Config

### Development

```env
NODE_ENV=development
PORT=3000
RATE_LIMIT_MAX_REQUESTS=1000  # Higher for testing
```

### Production

```env
NODE_ENV=production
PORT=3000
RATE_LIMIT_MAX_REQUESTS=100
ALLOWED_ORIGINS=https://your-scanner-app.com
```

---

## Security Checklist

Before going to production:

- [ ] Change default API keys
- [ ] Use strong random keys (32+ characters)
- [ ] Store keys in secure vault (1Password, AWS Secrets Manager)
- [ ] Enable HTTPS only
- [ ] Set appropriate rate limits
- [ ] Configure CORS for scanner app domain only
- [ ] Enable Supabase RLS policies (optional)
- [ ] Set up monitoring and alerts
- [ ] Document all API keys and their purposes
- [ ] Rotate keys regularly (monthly)

---

## Support Resources

- **API Documentation**: [README.md](README.md)
- **Deployment Guide**: [DEPLOYMENT.md](DEPLOYMENT.md)
- **Integration Guide**: [INTEGRATION.md](INTEGRATION.md)
- **Supabase Docs**: https://supabase.com/docs
- **Express.js Docs**: https://expressjs.com
- **TypeScript Docs**: https://www.typescriptlang.org/docs

---

## Getting Help

If you encounter issues:

1. Check the [Troubleshooting](#troubleshooting) section above
2. Review server logs: `npm run dev` output
3. Check Supabase logs in dashboard
4. Create GitHub issue with:
   - Error message
   - Steps to reproduce
   - Environment details (Node version, OS)

---

**Setup complete! Your Scanner API is ready to scan tickets. 🎉**
