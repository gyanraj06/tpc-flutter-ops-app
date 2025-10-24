# What You Need to Complete and Make It Work

This document lists everything you need to provide/configure to get the Scanner API fully operational.

## ✅ What's Already Done

The complete backend API is built with:
- All 7 API endpoints implemented
- HMAC signature verification
- Concurrent scan protection
- Complete audit logging
- Authentication & rate limiting
- Error handling
- Full documentation
- Testing utilities
- Deployment configs

---

## 🔧 What You Need to Do

### 1. Get Required Information (Critical)

#### A. Supabase Credentials

**From**: Supabase Dashboard → Settings → API

You need:
```env
VITE_SUPABASE_URL=https://????.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.????
```

#### B. QR Secret Key

**From**: Main Mounterra Vendor Portal codebase

⚠️ **CRITICAL**: This MUST be the EXACT same key used to generate QR codes.

**Location**: Check your main system's `.env` file or Vercel environment variables.

```env
QR_SECRET_KEY=your_64_character_hex_string
```

**How to find it**:
```bash
# In main system directory
grep QR_SECRET_KEY .env
```

Or check Vercel:
1. Go to Vercel Dashboard
2. Your project → Settings → Environment Variables
3. Find `QR_SECRET_KEY`

---

### 2. Install PostgreSQL Function

**What**: Run SQL script to create concurrent-safe ticket marking function

**Where**: Supabase Dashboard → SQL Editor

**How**:
1. Open `scanner-api/database/verify_and_use_ticket.sql`
2. Copy all contents
3. Paste in Supabase SQL Editor
4. Click "Run"

**Verify it worked**:
```sql
SELECT proname FROM pg_proc WHERE proname = 'verify_and_use_ticket';
```

Should return one row.

---

### 3. Configure Environment Variables

**File**: `scanner-api/.env`

**Steps**:
```bash
cd scanner-api
cp .env.example .env
nano .env  # or use your editor
```

**Fill in**:
```env
# From Supabase
VITE_SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# From main system (CRITICAL - must match)
QR_SECRET_KEY=your_secret_key

# Generate these (or use defaults for testing)
SCANNER_API_KEY=scanner_api_key_12345
ADMIN_API_KEY=admin_api_key_67890

# Leave these as-is for now
PORT=3000
NODE_ENV=development
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=100
```

---

### 4. Install Dependencies and Start

```bash
cd scanner-api
npm install
npm run dev
```

Should see:
```
[INFO] TPC Ops Scanner API started | Data: {"port":3000}
```

---

### 5. Test It Works

```bash
# Test 1: Health check
curl http://localhost:3000/health

# Test 2: Authentication
curl http://localhost:3000/api/scanner/scan-history \
  -H "Authorization: Bearer scanner_api_key_12345" \
  -H "X-Scanner-ID: test-scanner"
```

---

### 6. Test with Real Ticket

**Get a test ticket from your database**:

```sql
SELECT ticket_number, qr_code_data, qr_code_signature
FROM bulk_tickets
WHERE is_valid = true AND is_used = false
LIMIT 1;
```

**Generate test request**:

```bash
node scripts/generate-test-signature.js
```

Enter your QR_SECRET_KEY and ticket details, then run the generated cURL command.

**Expected**: Should return `"allowEntry": true`

**Verify**: Run same command again - should return `"already_used"`

---

## 📱 Scanner App Integration

The mobile app needs to be updated to:

### 1. Add API Configuration

```typescript
// config.ts
export const API_CONFIG = {
  baseURL: 'https://your-api-url.com',  // After deployment
  apiKey: 'scanner_api_key_12345',      // Your generated key
  scannerId: 'scanner-01',              // Unique per device
  scannerName: 'Gate 1',                // Human-readable
};
```

### 2. Implement API Call

See `INTEGRATION.md` for complete code examples.

**Key function**:
```typescript
async function verifyTicket(qrData: string, signature: string) {
  const response = await fetch(API_CONFIG.baseURL + '/api/scanner/verify-and-scan', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${API_CONFIG.apiKey}`,
      'X-Scanner-ID': API_CONFIG.scannerId,
    },
    body: JSON.stringify({ qrData, signature, markAsUsed: true }),
  });
  return response.json();
}
```

### 3. Update QR Code Format

**Important**: The main ticket generation system should encode BOTH data and signature in QR code:

```json
{
  "data": "{\"ticketNumber\":\"MTK1001\",...}",
  "signature": "abc123..."
}
```

The scanner app extracts both and sends to API.

---

## 🚀 Deployment

### Choose a Platform

**Easiest**: Vercel (recommended)
```bash
npm i -g vercel
vercel --prod
```

See `DEPLOYMENT.md` for complete instructions for:
- Vercel (serverless)
- Railway (PaaS)
- Render (PaaS)
- VPS (DigitalOcean, etc.)
- Docker

### Configure Production Environment

In your deployment platform (Vercel/Railway/etc.), set environment variables:
```
VITE_SUPABASE_URL=...
SUPABASE_SERVICE_ROLE_KEY=...
QR_SECRET_KEY=...
SCANNER_API_KEY=...
ADMIN_API_KEY=...
NODE_ENV=production
```

### Test Production

```bash
curl https://your-api-url.vercel.app/health
```

---

## 📋 Pre-Production Checklist

Before using at a real event:

### Database
- [ ] PostgreSQL function installed
- [ ] Tables have proper indexes
- [ ] Test tickets exist in database

### API Configuration
- [ ] QR_SECRET_KEY matches main system (CRITICAL!)
- [ ] Strong API keys generated
- [ ] Environment variables set in deployment platform
- [ ] Rate limits configured appropriately

### Testing
- [ ] Health check returns 200 OK
- [ ] Can verify test ticket successfully
- [ ] Duplicate scan returns "already_used"
- [ ] Invalid signature returns "signature_mismatch"
- [ ] Scan history retrieves records

### Mobile App
- [ ] API client configured with production URL
- [ ] API key stored securely
- [ ] QR scanner extracts data and signature correctly
- [ ] Result screens show green/red correctly
- [ ] Tested with at least 10 tickets

### Monitoring
- [ ] Uptime monitoring set up (Uptime Robot, etc.)
- [ ] Error tracking configured (optional - Sentry)
- [ ] Logs accessible

### Security
- [ ] HTTPS enabled (automatic on Vercel/Railway/Render)
- [ ] API keys rotated from defaults
- [ ] CORS configured for scanner app domain only
- [ ] Rate limiting enabled

### Test Event
- [ ] Small test event completed (10-20 tickets)
- [ ] No duplicate entries occurred
- [ ] Response time < 1 second
- [ ] Scanner app UX is smooth

---

## ❓ Common Questions

### Q: How do I know if my QR_SECRET_KEY is correct?

**A**: Generate a test signature using `scripts/generate-test-signature.js` with a ticket from your database. If verification succeeds, the key is correct.

### Q: Can I change the QR_SECRET_KEY?

**A**: Only if you regenerate ALL existing tickets. Otherwise, all old tickets will fail verification.

### Q: How many scanners can I have?

**A**: Unlimited. Each device should have a unique `scannerId` but can share the same `SCANNER_API_KEY`.

### Q: What if the API goes down during an event?

**A**: Implement offline mode in the scanner app (future feature). For now, ensure high availability by:
- Using reliable hosting (Vercel has 99.99% SLA)
- Setting up monitoring alerts
- Having a backup manual entry process

### Q: How do I add more scanner devices?

**A**: No API changes needed. Just:
1. Install scanner app on new device
2. Configure with same API_KEY but unique scannerId
3. Start scanning

---

## 🆘 If Something Doesn't Work

### Issue: API returns "Missing Supabase configuration"

**Check**:
1. `.env` file exists in scanner-api directory
2. Variables are set (not empty)
3. Restart the server after changing .env

### Issue: "Function verify_and_use_ticket does not exist"

**Fix**: Run `database/verify_and_use_ticket.sql` in Supabase SQL Editor

### Issue: All tickets return "signature_mismatch"

**Cause**: QR_SECRET_KEY doesn't match

**Fix**:
1. Find correct key from main system
2. Update scanner-api/.env
3. Restart server
4. Test again

### Issue: Tickets getting marked as used twice

**Cause**: PostgreSQL function not installed

**Fix**: Install the database function

---

## 📞 Get Help

1. **Read documentation**:
   - `QUICKSTART.md` - 5 minute setup
   - `SETUP.md` - Complete setup guide
   - `README.md` - Full API documentation
   - `INTEGRATION.md` - Mobile app integration

2. **Check logs**:
   ```bash
   # Development
   npm run dev  # Shows logs in console

   # Production (Vercel)
   vercel logs
   ```

3. **Test endpoints manually**:
   ```bash
   ./scripts/test-api.sh
   ```

4. **Contact support**:
   - GitHub Issues
   - Email: support@trippechalo.in

---

## 🎯 Summary: Minimum Required Steps

To make this work, you MUST:

1. ✅ Get Supabase credentials
2. ✅ Get QR_SECRET_KEY from main system
3. ✅ Create .env file with these values
4. ✅ Run database/verify_and_use_ticket.sql in Supabase
5. ✅ Install dependencies: `npm install`
6. ✅ Start server: `npm run dev`
7. ✅ Test with real ticket
8. ✅ Deploy to production
9. ✅ Update mobile app with API URL and key
10. ✅ Test end-to-end flow

**Time required**: 15-30 minutes for steps 1-7

---

## 🎉 Once It's Working

You'll have:
- ✅ Secure ticket verification
- ✅ Duplicate scan prevention
- ✅ Complete audit trail
- ✅ Real-time statistics
- ✅ Manual entry fallback
- ✅ Admin operations
- ✅ Production-ready API

**Ready to scan tickets! 🎫**
