# Final Implementation Checklist

Complete this checklist to get the Scanner API fully operational.

## 🎯 Phase 1: Initial Setup (15 minutes)

### ✅ Step 1: Verify Supabase Database

- [ ] Log into Supabase Dashboard
- [ ] Verify tables exist:
  - [ ] `bulk_ticket_batches`
  - [ ] `bulk_tickets`
  - [ ] `bulk_ticket_scans`
  - [ ] `bulk_ticket_generation_logs`
- [ ] Check that at least one test ticket exists:
  ```sql
  SELECT COUNT(*) FROM bulk_tickets;
  ```

### ✅ Step 2: Install PostgreSQL Function

- [ ] Open Supabase Dashboard → SQL Editor
- [ ] Open file: `scanner-api/database/verify_and_use_ticket.sql`
- [ ] Copy all contents
- [ ] Paste into SQL Editor
- [ ] Click "Run"
- [ ] Verify success:
  ```sql
  SELECT proname FROM pg_proc WHERE proname = 'verify_and_use_ticket';
  ```
  Should return: 1 row

### ✅ Step 3: Get Required Credentials

#### A. Supabase Credentials
- [ ] Go to Supabase Dashboard → Settings → API
- [ ] Copy Project URL: `https://?????.supabase.co`
- [ ] Copy service_role key (NOT anon key): `eyJhbGciOiJIUz...`

#### B. QR Secret Key
- [ ] Open main Mounterra Vendor Portal codebase
- [ ] Find QR_SECRET_KEY:
  ```bash
  grep QR_SECRET_KEY .env
  ```
  OR check Vercel environment variables
- [ ] Copy the EXACT value (must match!)

### ✅ Step 4: Configure Environment

- [ ] Navigate to scanner-api directory
- [ ] Copy template:
  ```bash
  cp .env.example .env
  ```
- [ ] Edit .env file:
  ```bash
  nano .env  # or use your editor
  ```
- [ ] Fill in these CRITICAL values:
  ```env
  VITE_SUPABASE_URL=https://your-project.supabase.co
  SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
  QR_SECRET_KEY=your_secret_key_from_main_system
  ```
- [ ] Save and close

### ✅ Step 5: Install Dependencies

```bash
cd scanner-api
npm install
```

- [ ] No errors during installation
- [ ] `node_modules/` folder created

### ✅ Step 6: Start Development Server

```bash
npm run dev
```

- [ ] Server starts without errors
- [ ] See log: `[INFO] TPC Ops Scanner API started`
- [ ] No "Missing configuration" errors

---

## 🧪 Phase 2: Testing (10 minutes)

### ✅ Test 1: Health Check

```bash
curl http://localhost:3000/health
```

**Expected**:
```json
{
  "status": "ok",
  "timestamp": "...",
  "uptime": 5.2,
  "environment": "development"
}
```

- [ ] Status is "ok"
- [ ] No errors

### ✅ Test 2: API Info

```bash
curl http://localhost:3000/api
```

**Expected**:
```json
{
  "name": "TPC Ops Scanner API",
  "version": "1.0.0",
  ...
}
```

- [ ] Returns API information
- [ ] Lists all endpoints

### ✅ Test 3: Authentication

```bash
curl http://localhost:3000/api/scanner/scan-history \
  -H "Authorization: Bearer scanner_api_key_12345" \
  -H "X-Scanner-ID: test-scanner-01"
```

**Expected**:
```json
{
  "success": true,
  "scans": [],
  "total": 0
}
```

- [ ] Authentication succeeds
- [ ] Returns empty scan history (initially)

### ✅ Test 4: Unauthorized Access

```bash
curl http://localhost:3000/api/scanner/scan-history
```

**Expected**:
```json
{
  "success": false,
  "error": "unauthorized"
}
```

- [ ] Returns 401 error
- [ ] Message says "Invalid API key"

### ✅ Test 5: Test with Real Ticket

#### A. Get Test Ticket

```sql
SELECT ticket_number, qr_code_data, qr_code_signature
FROM bulk_tickets
WHERE is_valid = true AND is_used = false
LIMIT 1;
```

- [ ] Copy ticket_number
- [ ] Copy qr_code_data
- [ ] Copy qr_code_signature

#### B. Generate Test Request

```bash
node scripts/generate-test-signature.js
```

- [ ] Enter your QR_SECRET_KEY
- [ ] Enter ticket details
- [ ] Copy generated cURL command

#### C. Run Verification

- [ ] Paste and run cURL command
- [ ] Response shows `"allowEntry": true`
- [ ] Response shows `"result": "valid_unused"`
- [ ] Ticket details are correct

#### D. Verify in Database

```sql
SELECT is_used, used_at FROM bulk_tickets WHERE ticket_number = 'MTK1001';
```

- [ ] `is_used` is now `true`
- [ ] `used_at` has timestamp

#### E. Test Duplicate Scan

- [ ] Run same cURL command again
- [ ] Response shows `"allowEntry": false`
- [ ] Response shows `"result": "already_used"`
- [ ] Previous `used_at` timestamp shown

### ✅ Test 6: Verify Logging

```sql
SELECT * FROM bulk_ticket_scans ORDER BY scanned_at DESC LIMIT 5;
```

- [ ] See entries for your test scans
- [ ] `scan_result` shows "success" and "already_used"
- [ ] Timestamps are correct

---

## 🚀 Phase 3: Deployment (30 minutes)

### ✅ Choose Deployment Platform

Pick one:
- [ ] Vercel (easiest, recommended)
- [ ] Railway
- [ ] Render
- [ ] VPS
- [ ] Docker

### ✅ Vercel Deployment (Recommended)

#### A. Install Vercel CLI

```bash
npm install -g vercel
```

- [ ] Vercel CLI installed

#### B. Login

```bash
vercel login
```

- [ ] Logged into Vercel account

#### C. Configure Project

- [ ] Verify `vercel.json` exists in scanner-api/
- [ ] No changes needed to vercel.json

#### D. Set Environment Variables

Option 1 - Via CLI:
```bash
vercel env add VITE_SUPABASE_URL
vercel env add SUPABASE_SERVICE_ROLE_KEY
vercel env add QR_SECRET_KEY
vercel env add SCANNER_API_KEY
vercel env add ADMIN_API_KEY
vercel env add NODE_ENV
```

Option 2 - Via Dashboard:
- [ ] Go to Vercel Dashboard → Your Project → Settings → Environment Variables
- [ ] Add all variables from .env file
- [ ] Set for Production environment

#### E. Deploy

```bash
vercel --prod
```

- [ ] Deployment succeeds
- [ ] Get production URL: `https://your-app.vercel.app`

#### F. Test Production

```bash
curl https://your-app.vercel.app/health
```

- [ ] Health check returns 200 OK
- [ ] Environment shows "production"

---

## 📱 Phase 4: Mobile App Integration (1-2 hours)

### ✅ Update Mobile App Configuration

- [ ] Open scanner app codebase
- [ ] Create/update API config file:
  ```typescript
  export const API_CONFIG = {
    baseURL: 'https://your-app.vercel.app',
    apiKey: 'scanner_api_key_12345',
    scannerId: 'scanner-01',
    scannerName: 'Gate 1 - Main Entrance',
  };
  ```

### ✅ Implement API Client

- [ ] Follow code examples in `INTEGRATION.md`
- [ ] Create `services/ticketVerification.ts`
- [ ] Create `api/scannerClient.ts`
- [ ] Add error handling

### ✅ Update QR Scanner

- [ ] Ensure QR scanner extracts both `data` and `signature`
- [ ] Expected format:
  ```json
  {
    "data": "{\"ticketNumber\":\"MTK1001\",...}",
    "signature": "abc123..."
  }
  ```

### ✅ Update Result Screens

- [ ] Green screen for `valid_unused` → ALLOW ENTRY
- [ ] Red screen for `already_used`, `invalid`, `signature_mismatch` → DENY
- [ ] Yellow screen for `not_found` → MANUAL CHECK

### ✅ Test Mobile Integration

- [ ] Scan test ticket QR code
- [ ] API call succeeds
- [ ] Green screen shows for valid ticket
- [ ] Scan same ticket again
- [ ] Red screen shows for already used
- [ ] Response time < 2 seconds

---

## 🛡️ Phase 5: Security & Monitoring (30 minutes)

### ✅ Security Hardening

- [ ] Change default API keys to strong random values:
  ```bash
  node -e "console.log('scanner_' + require('crypto').randomBytes(16).toString('hex'))"
  ```
- [ ] Update SCANNER_API_KEY in:
  - [ ] Vercel environment variables
  - [ ] Mobile app config
- [ ] Update ADMIN_API_KEY in Vercel
- [ ] Document new keys in secure vault (1Password, etc.)

### ✅ Configure CORS

- [ ] In Vercel environment variables, add:
  ```
  ALLOWED_ORIGINS=https://your-scanner-app-domain.com
  ```
- [ ] Or leave as `*` for testing (NOT for production)

### ✅ Set Up Monitoring

#### A. Uptime Monitoring
- [ ] Sign up for Uptime Robot (free)
- [ ] Add monitor for `https://your-app.vercel.app/health`
- [ ] Set check interval: 5 minutes
- [ ] Add email alert

#### B. Error Tracking (Optional)
- [ ] Sign up for Sentry (optional)
- [ ] Add Sentry SDK to `src/index.ts`
- [ ] Configure DSN in environment variables

### ✅ Review Logs

- [ ] Vercel Dashboard → Your Project → Deployments → View Logs
- [ ] Verify no errors in logs
- [ ] Check that scans are being logged

---

## 🎪 Phase 6: Test Event (1-2 hours)

### ✅ Plan Test Event

- [ ] Create test batch with 20-50 tickets
- [ ] Generate and send tickets to test users
- [ ] Set up 1-2 scanner devices
- [ ] Brief scanner operators

### ✅ During Test Event

- [ ] Scan first ticket successfully
- [ ] Verify green screen shows
- [ ] Try scanning same ticket twice
- [ ] Verify red screen shows
- [ ] Test damaged QR code scenario
- [ ] Use manual entry endpoint
- [ ] Monitor scan history in real-time

### ✅ Verify Test Results

```sql
-- Check total scans
SELECT COUNT(*) FROM bulk_ticket_scans;

-- Check for duplicates (should be 0)
SELECT ticket_id, COUNT(*) as scan_count
FROM bulk_ticket_scans
WHERE scan_result = 'success'
GROUP BY ticket_id
HAVING COUNT(*) > 1;

-- Check success rate
SELECT
  scan_result,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM bulk_ticket_scans
GROUP BY scan_result;
```

- [ ] No duplicate successful scans
- [ ] Success rate > 95%
- [ ] All timestamps correct
- [ ] Scanner IDs logged correctly

---

## ✅ Phase 7: Production Readiness

### ✅ Documentation

- [ ] Document API keys and where they're stored
- [ ] Document deployment URL
- [ ] Document scanner device IDs
- [ ] Create runbook for common issues
- [ ] Train event staff on scanner app

### ✅ Backup & Recovery

- [ ] Verify Supabase automatic backups enabled
- [ ] Document recovery procedure
- [ ] Test database restore (optional)

### ✅ Performance Review

- [ ] Average scan response time < 500ms
- [ ] No timeouts during test event
- [ ] Database indexes working efficiently
- [ ] Rate limits appropriate

### ✅ Final Checks

- [ ] All environment variables set in production
- [ ] PostgreSQL function installed
- [ ] QR_SECRET_KEY matches main system
- [ ] Scanner API keys rotated from defaults
- [ ] CORS configured correctly
- [ ] Monitoring active
- [ ] Mobile app tested end-to-end
- [ ] Test event completed successfully
- [ ] No duplicate scan entries in database
- [ ] Team trained on operations

---

## 🎉 Launch Day Checklist

### Before Event Starts

- [ ] Verify API health check returns 200 OK
- [ ] Test scan one ticket successfully
- [ ] Verify monitoring is active
- [ ] Scanner devices charged and connected
- [ ] Scanner operators briefed
- [ ] Manual entry procedure documented
- [ ] Support contact available

### During Event

- [ ] Monitor uptime alerts
- [ ] Check scan success rate hourly
- [ ] Watch for error spikes in logs
- [ ] Be available for support

### After Event

- [ ] Review scan statistics
- [ ] Check for any duplicate entries
- [ ] Review error logs
- [ ] Document any issues encountered
- [ ] Gather feedback from scanner operators

---

## 🆘 Troubleshooting Quick Reference

### Issue: API returns "Missing Supabase configuration"
**Fix**: Check .env file exists and has correct values, restart server

### Issue: "Function verify_and_use_ticket does not exist"
**Fix**: Run `database/verify_and_use_ticket.sql` in Supabase SQL Editor

### Issue: All tickets return "signature_mismatch"
**Fix**: QR_SECRET_KEY doesn't match main system - get correct key and restart

### Issue: Slow response times (> 2 seconds)
**Check**: Network latency, Supabase region, database connection pool

### Issue: Scanner app can't connect to API
**Check**: API URL correct, CORS configured, API key valid

---

## 📊 Success Criteria

You're ready for production when:

- ✅ All tests pass
- ✅ Test event completed with 0 duplicate entries
- ✅ Response time < 500ms average
- ✅ Success rate > 99%
- ✅ Monitoring active and alerting
- ✅ Team trained and confident
- ✅ Documentation complete
- ✅ Backup/recovery tested

---

## 📞 Support Resources

- **Documentation**: All .md files in scanner-api/
- **Supabase Logs**: Dashboard → Logs
- **Vercel Logs**: Dashboard → Deployments → View Logs
- **API Testing**: `scripts/test-api.sh`
- **Signature Generator**: `scripts/generate-test-signature.js`

---

## ✨ Congratulations!

When all items are checked, your Scanner API is production-ready! 🎊

**Estimated Total Time**: 3-4 hours from start to production-ready

**Next**: Start scanning tickets at your first event! 🎫
