# Scanner API - File Overview

Quick reference guide to all files in the project.

## 📁 Project Structure

```
scanner-api/
├── 📄 Configuration Files
├── 📚 Documentation Files
├── 🗄️ Database Files
├── 🔧 Scripts
└── 💻 Source Code
```

---

## 📄 Configuration Files

### `package.json`
**Purpose**: Node.js dependencies and scripts
**Key Scripts**:
- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm start` - Run production build

### `tsconfig.json`
**Purpose**: TypeScript configuration
**Key Settings**: ES2020 target, strict mode enabled

### `.env.example`
**Purpose**: Template for environment variables
**Action Required**: Copy to `.env` and fill in values

### `.gitignore`
**Purpose**: Files to exclude from git
**Ignores**: node_modules, .env, dist/, logs

### `vercel.json`
**Purpose**: Vercel deployment configuration
**Settings**: Route all requests to Express app

---

## 📚 Documentation Files

### `README.md` ⭐ **START HERE**
**Purpose**: Complete API documentation
**Contains**:
- All endpoint descriptions
- Request/response examples
- Authentication guide
- Error codes
- Testing examples

### `QUICKSTART.md` ⚡
**Purpose**: 5-minute setup guide
**For**: Getting API running quickly
**Contains**: Minimal steps to start server

### `SETUP.md` 🔧
**Purpose**: Detailed setup instructions
**For**: Complete installation process
**Contains**: Step-by-step with troubleshooting

### `DEPLOYMENT.md` 🚀
**Purpose**: Production deployment guide
**For**: Deploying to various platforms
**Contains**: Instructions for Vercel, Railway, Render, VPS, Docker

### `INTEGRATION.md` 📱
**Purpose**: Mobile app integration guide
**For**: Scanner app developers
**Contains**: Complete code examples for React Native/Flutter

### `PROJECT_SUMMARY.md` 📋
**Purpose**: High-level project overview
**For**: Understanding what was built
**Contains**: Features, architecture, status

### `WHAT_YOU_NEED.md` ✅ **CRITICAL**
**Purpose**: What you need to provide to make it work
**For**: Implementation checklist
**Contains**: Required credentials, configuration steps

### `FILE_OVERVIEW.md` (This file)
**Purpose**: Guide to all files in project

---

## 🗄️ Database Files

### `database/verify_and_use_ticket.sql`
**Purpose**: PostgreSQL function for concurrent-safe ticket marking
**Action Required**: Run in Supabase SQL Editor
**Critical**: Must be installed before API works
**What it does**:
- Locks ticket row to prevent duplicates
- Marks ticket as used atomically
- Logs scan in one transaction

---

## 🔧 Scripts

### `scripts/generate-test-signature.js`
**Purpose**: Generate HMAC signatures for testing
**Usage**: `node scripts/generate-test-signature.js`
**Interactive**: Prompts for ticket details
**Output**: cURL command and JSON body for testing

### `scripts/test-api.sh`
**Purpose**: Automated API test suite
**Usage**: `./scripts/test-api.sh`
**Tests**: All endpoints with various scenarios
**Requires**: jq (JSON processor)

---

## 💻 Source Code

### `src/index.ts` - Main Entry Point
**Purpose**: Express app initialization
**Contains**:
- Server setup
- Middleware configuration
- Route mounting
- Error handling
- Health check endpoint

**Key Routes**:
- `GET /health` - Health check
- `GET /api` - API info
- `/api/scanner/*` - All scanner endpoints

---

### Middleware (`src/middleware/`)

#### `auth.ts`
**Purpose**: Authentication middleware
**Functions**:
- `authenticateScanner()` - Validates scanner API key
- `authenticateAdmin()` - Validates admin API key
**Checks**: Authorization header, X-Scanner-ID header

#### `rateLimit.ts`
**Purpose**: Rate limiting configurations
**Limits**:
- Verify endpoints: 100/min
- History/stats: 20/min
- Admin: 10/min

#### `errorHandler.ts`
**Purpose**: Global error handling
**Functions**:
- `errorHandler()` - Catches all errors
- `notFoundHandler()` - 404 responses
- `asyncHandler()` - Async route wrapper

---

### Routes (`src/routes/`)

#### `verify.ts` - QR Verification
**Endpoints**:
- `POST /api/scanner/verify-and-scan` - Main verification
- `POST /api/scanner/verify-only` - Preview mode

**Process**:
1. Verify HMAC signature
2. Check ticket status
3. Mark as used (if requested)
4. Return allow/deny decision

#### `tickets.ts` - Ticket Lookup
**Endpoints**:
- `GET /api/scanner/ticket-details?ticketNumber=MTK1001`

**Returns**: Full ticket info + scan history

#### `history.ts` - Scan History
**Endpoints**:
- `GET /api/scanner/scan-history?scannerId=...&batchId=...`

**Features**: Pagination, filtering by scanner/batch/date

#### `stats.ts` - Statistics
**Endpoints**:
- `GET /api/scanner/batch-stats?batchId=...`

**Returns**: Real-time ticket usage statistics

#### `admin.ts` - Admin Operations
**Endpoints**:
- `POST /api/scanner/manual-entry` - Manual ticket entry
- `POST /api/scanner/undo-scan` - Undo scan (admin only)

**Requires**: Admin API key

---

### Services (`src/services/`)

#### `qrService.ts` - QR Verification
**Purpose**: HMAC signature verification
**Functions**:
- `verifyQRCode()` - Verify signature and parse data

**Security**: Timing-safe comparison prevents timing attacks

#### `ticketService.ts` - Ticket Operations
**Purpose**: All ticket database operations
**Functions**:
- `getTicketByNumber()` - Fetch ticket
- `verifyTicketStatus()` - Check if valid/unused
- `markTicketAsUsed()` - Mark as used via DB function
- `getTicketDetails()` - Full details with history
- `manualEntry()` - Manual ticket entry
- `undoScan()` - Reverse a scan

#### `scanService.ts` - Scan Logging
**Purpose**: Scan history and statistics
**Functions**:
- `getScanHistory()` - Query scan logs
- `getBatchStats()` - Calculate statistics
- `logScan()` - Manual scan logging

---

### Utils (`src/utils/`)

#### `supabase.ts` - Database Client
**Purpose**: Supabase client configuration
**Exports**:
- `getSupabaseClient()` - Singleton client
- Database type definitions

#### `crypto.ts` - Cryptography
**Purpose**: HMAC utilities
**Functions**:
- `verifyQRSignature()` - Verify HMAC-SHA256
- `parseQRData()` - Parse and validate JSON
- `generateQRSignature()` - Generate signature (testing)

#### `logger.ts` - Logging
**Purpose**: Structured logging
**Functions**:
- `logger.info()` - Info logs
- `logger.warn()` - Warnings
- `logger.error()` - Errors
- `logger.debug()` - Debug (dev only)

**Format**: `[timestamp] [level] message | data`

---

### Types (`src/types/`)

#### `scanner.types.ts` - TypeScript Types
**Purpose**: Type definitions for API
**Types**:
- `ScanResult` - Enum of possible results
- `VerifyScanRequest` - Request body type
- `VerifyScanResponse` - Response type
- `TicketInfo`, `BatchInfo` - Data structures
- `ApiError` - Error response type

---

## 📊 File Statistics

| Category | Files | Lines of Code (approx) |
|----------|-------|------------------------|
| Source Code | 15 | ~2,500 |
| Documentation | 8 | ~3,000 |
| Configuration | 5 | ~100 |
| Database | 1 | ~80 |
| Scripts | 2 | ~150 |
| **Total** | **31** | **~5,830** |

---

## 🔍 File Dependencies

```
index.ts
├── middleware/
│   ├── auth.ts
│   ├── rateLimit.ts
│   └── errorHandler.ts
├── routes/
│   ├── verify.ts → services/qrService.ts, services/ticketService.ts
│   ├── tickets.ts → services/ticketService.ts
│   ├── history.ts → services/scanService.ts
│   ├── stats.ts → services/scanService.ts
│   └── admin.ts → services/ticketService.ts
└── services/
    ├── qrService.ts → utils/crypto.ts, utils/logger.ts
    ├── ticketService.ts → utils/supabase.ts, utils/logger.ts
    └── scanService.ts → utils/supabase.ts, utils/logger.ts
```

---

## 🎯 Critical Files (Must Configure)

1. **`.env`** - Environment variables (copy from .env.example)
2. **`database/verify_and_use_ticket.sql`** - Run in Supabase
3. **`package.json`** - npm install dependencies

---

## 📖 Reading Order for New Developers

1. `QUICKSTART.md` - Get it running
2. `README.md` - Understand API
3. `PROJECT_SUMMARY.md` - Understand architecture
4. `src/index.ts` - Entry point
5. `src/routes/verify.ts` - Main logic
6. `src/services/ticketService.ts` - Core operations
7. `INTEGRATION.md` - Mobile app integration

---

## 🔧 Files You'll Edit Most

### During Setup:
- `.env` - Configuration
- Nothing else!

### During Development:
- `src/routes/*.ts` - Add endpoints
- `src/services/*.ts` - Business logic
- `src/middleware/*.ts` - Add middleware
- `database/*.sql` - Database changes

### During Deployment:
- `vercel.json` - Vercel config
- Environment variables in platform dashboard

---

## 🚫 Files You Should NOT Edit

- `package.json` - Unless adding dependencies
- `tsconfig.json` - TypeScript config is optimized
- `.gitignore` - Already comprehensive
- `node_modules/` - Never edit directly
- `dist/` - Build output (auto-generated)

---

## 💡 Tips

### To Find Something:

**Find endpoint**: Look in `src/routes/`
**Find business logic**: Look in `src/services/`
**Find types**: Look in `src/types/scanner.types.ts`
**Find docs**: All `.md` files in root

### To Add a Feature:

1. Add types in `src/types/scanner.types.ts`
2. Add service function in appropriate `src/services/*.ts`
3. Add route in appropriate `src/routes/*.ts`
4. Test with cURL
5. Document in `README.md`

### To Debug:

1. Check `npm run dev` console output
2. Look for ERROR logs
3. Check Supabase dashboard logs
4. Use `logger.debug()` for debugging

---

## 📝 Cheat Sheet

```bash
# Start dev server
npm run dev

# Build for production
npm run build

# Run production build
npm start

# Type check
npm run type-check

# Generate test signature
node scripts/generate-test-signature.js

# Test API
./scripts/test-api.sh

# View logs (development)
npm run dev  # Shows in console

# View logs (production - Vercel)
vercel logs
```

---

**Quick navigation complete! 🗺️**
