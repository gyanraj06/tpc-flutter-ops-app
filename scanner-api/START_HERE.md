# 🎯 START HERE - TPC Ops Scanner API

**Welcome!** This is your complete QR code ticket scanner backend API.

## 📚 Where to Start

### 🚀 If you want to get it running FAST (5 minutes):
➡️ **Read**: [QUICKSTART.md](QUICKSTART.md)

### 📖 If you want detailed setup instructions:
➡️ **Read**: [SETUP.md](SETUP.md)

### ✅ If you want a complete implementation checklist:
➡️ **Read**: [FINAL_CHECKLIST.md](FINAL_CHECKLIST.md)

### 📱 If you're integrating with mobile app:
➡️ **Read**: [INTEGRATION.md](INTEGRATION.md)

### 🚀 If you're deploying to production:
➡️ **Read**: [DEPLOYMENT.md](DEPLOYMENT.md)

---

## 🎯 What This System Does

This backend API provides:

✅ **QR Code Verification** - Cryptographic HMAC-SHA256 signature validation
✅ **Ticket Validation** - Real-time status checking (valid/invalid, used/unused)
✅ **Entry Management** - Atomic ticket marking with concurrent protection
✅ **Audit Logging** - Complete scan history for compliance
✅ **Statistics** - Real-time event metrics and analytics
✅ **Admin Tools** - Manual entry, undo scans, ticket lookup

---

## 🏗️ System Architecture

```
┌─────────────────┐
│  Scanner Apps   │  (Mobile - React Native/Flutter)
│  Multiple Gates │
└────────┬────────┘
         │ HTTPS
         ▼
┌─────────────────┐
│  Scanner API    │  (This System - Node.js/Express)
│  Vercel/Railway │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Supabase DB    │  (PostgreSQL)
│  Bulk Tickets   │
└─────────────────┘
```

---

## 🎯 Critical Requirements

Before you start, you MUST have:

1. **Supabase Account** with bulk ticket tables already created
2. **QR_SECRET_KEY** from your main ticket generation system
3. **Node.js 18+** installed on your machine

---

## 📁 Project Structure

```
scanner-api/
├── 📚 Documentation (9 files)
│   ├── START_HERE.md           ⭐ This file
│   ├── QUICKSTART.md           ⚡ 5-min setup
│   ├── SETUP.md                🔧 Detailed setup
│   ├── FINAL_CHECKLIST.md      ✅ Implementation checklist
│   ├── WHAT_YOU_NEED.md        📋 Required info
│   ├── README.md               📖 Complete API docs
│   ├── INTEGRATION.md          📱 Mobile app guide
│   ├── DEPLOYMENT.md           🚀 Deployment guide
│   ├── PROJECT_SUMMARY.md      📊 Project overview
│   └── FILE_OVERVIEW.md        🗺️ File guide
│
├── 💻 Source Code (15 files)
│   ├── src/index.ts            - Main Express app
│   ├── src/routes/             - API endpoints (5 files)
│   ├── src/services/           - Business logic (3 files)
│   ├── src/middleware/         - Auth, rate limit (3 files)
│   ├── src/utils/              - Helpers (3 files)
│   └── src/types/              - TypeScript types (1 file)
│
├── 🗄️ Database (1 file)
│   └── database/verify_and_use_ticket.sql
│
├── 🔧 Scripts (2 files)
│   ├── scripts/generate-test-signature.js
│   └── scripts/test-api.sh
│
└── ⚙️ Config (5 files)
    ├── package.json
    ├── tsconfig.json
    ├── .env.example
    ├── .gitignore
    └── vercel.json
```

---

## 🚦 Quick Status Check

### ✅ What's Complete

- [x] All 7 API endpoints implemented
- [x] HMAC signature verification
- [x] Concurrent scan protection
- [x] Complete audit logging
- [x] Authentication & rate limiting
- [x] Error handling
- [x] TypeScript types
- [x] Full documentation
- [x] Testing utilities
- [x] Deployment configs

### ⏳ What You Need to Do

- [ ] Get Supabase credentials
- [ ] Get QR_SECRET_KEY from main system
- [ ] Install PostgreSQL function
- [ ] Configure .env file
- [ ] Start server and test
- [ ] Deploy to production
- [ ] Integrate with mobile app
- [ ] Run test event

**Total Time**: 3-4 hours

---

## 🎓 Learning Path

### For Implementers (Using the API)

1. Read [QUICKSTART.md](QUICKSTART.md) - Get it running
2. Read [WHAT_YOU_NEED.md](WHAT_YOU_NEED.md) - Required info
3. Complete [FINAL_CHECKLIST.md](FINAL_CHECKLIST.md) - Step by step
4. Read [DEPLOYMENT.md](DEPLOYMENT.md) - Go to production
5. Read [INTEGRATION.md](INTEGRATION.md) - Connect mobile app

### For Developers (Modifying the API)

1. Read [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Understand architecture
2. Read [FILE_OVERVIEW.md](FILE_OVERVIEW.md) - Understand codebase
3. Read `src/index.ts` - Entry point
4. Read `src/routes/verify.ts` - Main logic
5. Read [README.md](README.md) - API documentation

---

## 🔥 Common Use Cases

### "I just want to see if it works"
➡️ Go to [QUICKSTART.md](QUICKSTART.md)

### "I need to set this up for production"
➡️ Go to [FINAL_CHECKLIST.md](FINAL_CHECKLIST.md)

### "My mobile app needs to connect"
➡️ Go to [INTEGRATION.md](INTEGRATION.md)

### "I need to deploy this"
➡️ Go to [DEPLOYMENT.md](DEPLOYMENT.md)

### "What do I need to provide?"
➡️ Go to [WHAT_YOU_NEED.md](WHAT_YOU_NEED.md)

### "How does this work?"
➡️ Go to [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)

### "Where's the API documentation?"
➡️ Go to [README.md](README.md)

---

## 🎯 5-Minute Quick Start

If you want to skip reading and just get started:

```bash
# 1. Install
cd scanner-api
npm install

# 2. Configure
cp .env.example .env
# Edit .env - add your Supabase URL, service key, and QR secret key

# 3. Install database function
# Run database/verify_and_use_ticket.sql in Supabase SQL Editor

# 4. Start
npm run dev

# 5. Test
curl http://localhost:3000/health
```

**Done!** Now read the documentation to understand what you just did.

---

## 💡 Key Concepts

### HMAC Signature Verification
Every QR code has a cryptographic signature. The API verifies this signature to prevent fake tickets.

### Concurrent Scan Protection
Uses PostgreSQL row-level locking to ensure a ticket can't be scanned twice at the same time.

### Audit Trail
Every scan attempt (success or failure) is logged with timestamp, scanner ID, and result.

### Stateless API
No sessions or cookies. Each request is authenticated via API key.

---

## 🔑 Critical Information

### ⚠️ QR_SECRET_KEY Must Match
The `QR_SECRET_KEY` in your `.env` file **MUST** be the exact same key used in your main ticket generation system. If they don't match, ALL scans will fail.

### ⚠️ PostgreSQL Function Required
The `verify_and_use_ticket` function MUST be installed in Supabase. Without it, concurrent scans won't be protected.

### ⚠️ Use Service Role Key
You need the `service_role` key from Supabase, NOT the `anon` key. The service role key bypasses Row Level Security.

---

## 📊 API Endpoints Summary

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/health` | GET | Health check |
| `/api/scanner/verify-and-scan` | POST | Verify & mark ticket |
| `/api/scanner/verify-only` | POST | Verify without marking |
| `/api/scanner/ticket-details` | GET | Ticket lookup |
| `/api/scanner/scan-history` | GET | Scan audit trail |
| `/api/scanner/batch-stats` | GET | Event statistics |
| `/api/scanner/manual-entry` | POST | Manual ticket entry |
| `/api/scanner/undo-scan` | POST | Undo scan (admin) |

Full documentation in [README.md](README.md)

---

## 🆘 Need Help?

### Documentation Issues
- All documentation files are in the root directory
- File names are descriptive: QUICKSTART, SETUP, DEPLOYMENT, etc.

### Setup Issues
- Check [SETUP.md](SETUP.md) troubleshooting section
- Review [WHAT_YOU_NEED.md](WHAT_YOU_NEED.md) for missing items

### API Issues
- Check server logs: `npm run dev` output
- Review [README.md](README.md) error codes section
- Test with: `./scripts/test-api.sh`

### Integration Issues
- Check [INTEGRATION.md](INTEGRATION.md) for mobile app code examples
- Verify API_KEY and API_URL are correct

---

## 🎉 Success Criteria

You'll know it's working when:

✅ Health check returns 200 OK
✅ Test ticket verification succeeds
✅ Duplicate scan returns "already_used"
✅ Invalid signature returns "signature_mismatch"
✅ Scans are logged in database
✅ Mobile app can scan and verify tickets
✅ Response time < 500ms

---

## 📞 Support

- **Documentation**: All .md files in this directory
- **Issues**: Create GitHub issue with error details
- **Email**: support@trippechalo.in

---

## 🚀 Next Steps

**Choose your path**:

1. **Quick Test** → [QUICKSTART.md](QUICKSTART.md)
2. **Full Setup** → [FINAL_CHECKLIST.md](FINAL_CHECKLIST.md)
3. **Learn More** → [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)

---

## 📝 Maintenance

Once deployed, regular tasks:

- **Daily**: Monitor health and error logs
- **Weekly**: Review scan statistics
- **Monthly**: Rotate API keys, check for updates

---

**Ready to start? Pick a guide above and let's build! 🚀**
