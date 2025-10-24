# System Flow Diagrams

Visual guide to understanding how the Scanner API works.

---

## 🎫 Complete Ticket Scanning Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     TICKET SCANNING FLOW                         │
└─────────────────────────────────────────────────────────────────┘

1. USER SCANS QR CODE
   ↓
   📱 Scanner App (Mobile)
   ├─ Camera captures QR code
   ├─ Extracts: { data: "...", signature: "..." }
   └─ Parses ticket info

2. SEND TO API
   ↓
   🌐 HTTPS POST /api/scanner/verify-and-scan
   ├─ Headers:
   │  ├─ Authorization: Bearer <API_KEY>
   │  ├─ X-Scanner-ID: scanner-01
   │  └─ X-Scanner-Name: Gate 1
   └─ Body:
      ├─ qrData: JSON string
      ├─ signature: HMAC hex
      └─ markAsUsed: true

3. AUTHENTICATION
   ↓
   🔐 Middleware: authenticateScanner()
   ├─ Verify API key matches
   ├─ Verify Scanner ID present
   └─ ✅ PASS → Continue
       ❌ FAIL → Return 401

4. RATE LIMITING
   ↓
   ⏱️ Middleware: verifyRateLimit()
   ├─ Check: < 100 requests/min
   └─ ✅ PASS → Continue
       ❌ FAIL → Return 429

5. VERIFY SIGNATURE
   ↓
   🔒 QRService.verifyQRCode()
   ├─ Generate expected HMAC
   ├─ Compare with timing-safe equality
   └─ ✅ MATCH → Continue to Step 6
       ❌ MISMATCH → Return "signature_mismatch"

6. DATABASE LOOKUP & ATOMIC MARK
   ↓
   🗄️ PostgreSQL Function: verify_and_use_ticket()
   │
   ├─ BEGIN TRANSACTION
   │
   ├─ SELECT * FROM bulk_tickets
   │  WHERE ticket_number = 'MTK1001'
   │  FOR UPDATE;  ← ROW LOCK (prevents concurrent access)
   │
   ├─ IF ticket NOT FOUND
   │  └─ Return "not_found"
   │
   ├─ IF ticket.is_valid = false
   │  └─ Return "invalid"
   │
   ├─ IF ticket.is_used = true
   │  └─ Return "already_used"
   │
   ├─ ✅ TICKET IS VALID & UNUSED
   │  ├─ UPDATE bulk_tickets
   │  │  SET is_used = true, used_at = NOW()
   │  │  WHERE id = ticket.id;
   │  │
   │  └─ INSERT INTO bulk_ticket_scans
   │     (ticket_id, batch_id, scan_result, scanned_by)
   │     VALUES (..., 'success', 'Gate 1');
   │
   └─ COMMIT TRANSACTION

7. BUILD RESPONSE
   ↓
   📦 Route Handler: verify.ts
   ├─ result: "valid_unused"
   ├─ allowEntry: true
   ├─ ticket: { ticketNumber, customerName, ... }
   └─ batch: { eventTitle, venue }

8. RETURN TO APP
   ↓
   📱 Scanner App Receives Response
   │
   ├─ IF allowEntry = true
   │  └─ 🟢 SHOW GREEN SCREEN: "ALLOW ENTRY"
   │     ├─ Display ticket info
   │     ├─ Play success sound
   │     └─ Vibrate (success pattern)
   │
   └─ IF allowEntry = false
      └─ 🔴 SHOW RED SCREEN: "DENY ENTRY"
         ├─ Display reason (already_used, invalid, etc.)
         ├─ Play error sound
         └─ Vibrate (error pattern)

9. AUTO RESET
   ↓
   ⏰ After 5 seconds
   └─ Return to scan mode
```

---

## 🔒 Security Verification Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                  SECURITY VERIFICATION LAYERS                    │
└─────────────────────────────────────────────────────────────────┘

INCOMING REQUEST
    ↓
┌───────────────────────────────────────┐
│ LAYER 1: API KEY AUTHENTICATION       │
│ ✓ Authorization header present?       │
│ ✓ Bearer token matches SCANNER_API_KEY? │
│ ✓ X-Scanner-ID header present?        │
└───────────┬───────────────────────────┘
            ↓ PASS
┌───────────────────────────────────────┐
│ LAYER 2: RATE LIMITING                │
│ ✓ < 100 requests/min from this scanner? │
│ ✓ No burst attacks?                   │
└───────────┬───────────────────────────┘
            ↓ PASS
┌───────────────────────────────────────┐
│ LAYER 3: HMAC SIGNATURE VERIFICATION  │
│ ✓ Signature format valid (hex)?       │
│ ✓ Generate expected HMAC-SHA256       │
│ ✓ Timing-safe comparison              │
└───────────┬───────────────────────────┘
            ↓ PASS
┌───────────────────────────────────────┐
│ LAYER 4: DATABASE VALIDATION          │
│ ✓ Ticket exists in database?          │
│ ✓ Ticket is marked as valid?          │
│ ✓ Ticket not already used?            │
└───────────┬───────────────────────────┘
            ↓ PASS
┌───────────────────────────────────────┐
│ LAYER 5: CONCURRENT PROTECTION        │
│ ✓ Row-level lock acquired?            │
│ ✓ Re-check not used (race condition)? │
│ ✓ Atomic update successful?           │
└───────────┬───────────────────────────┘
            ↓ ALL PASS
        ✅ ALLOW ENTRY
```

---

## 🔄 Concurrent Scan Protection

```
┌─────────────────────────────────────────────────────────────────┐
│           WHAT HAPPENS WITH SIMULTANEOUS SCANS?                  │
└─────────────────────────────────────────────────────────────────┘

SCENARIO: Same ticket scanned at Gate 1 and Gate 2 simultaneously

TIME: 08:30:00.000
├─ Gate 1: Scans ticket MTK1001
└─ Gate 2: Scans ticket MTK1001 (2ms later)

BOTH REQUESTS HIT API
├─ Gate 1: POST /verify-and-scan
└─ Gate 2: POST /verify-and-scan

BOTH REACH DATABASE FUNCTION
┌──────────────────────────────────┬──────────────────────────────────┐
│          GATE 1 THREAD           │          GATE 2 THREAD           │
├──────────────────────────────────┼──────────────────────────────────┤
│ SELECT ... FOR UPDATE            │ SELECT ... FOR UPDATE            │
│ ✓ Acquires ROW LOCK immediately  │ ⏳ WAITS for lock to be released │
│                                  │                                  │
│ Check: is_used = false ✓         │    (blocked, waiting...)         │
│ UPDATE: is_used = true           │                                  │
│ INSERT scan log                  │                                  │
│ COMMIT                           │                                  │
│ ✅ Return "valid_unused"         │                                  │
│                                  │                                  │
│ 🔓 RELEASES LOCK                 │                                  │
│                                  │ ✓ Now acquires lock              │
│                                  │ Check: is_used = true ❌         │
│                                  │ No update performed              │
│                                  │ INSERT scan log ("already_used") │
│                                  │ COMMIT                           │
│                                  │ ❌ Return "already_used"         │
└──────────────────────────────────┴──────────────────────────────────┘

RESULT
├─ Gate 1: 🟢 ALLOW ENTRY (winner)
└─ Gate 2: 🔴 DENY ENTRY (loser)

DATABASE FINAL STATE
└─ bulk_tickets: is_used = true, used_at = '08:30:00.001'
└─ bulk_ticket_scans:
   ├─ Row 1: scan_result = 'success', scanned_by = 'Gate 1'
   └─ Row 2: scan_result = 'already_used', scanned_by = 'Gate 2'

✅ NO DUPLICATE ENTRY POSSIBLE
```

---

## 📊 Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     DATA FLOW ARCHITECTURE                       │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                        SCANNER DEVICES                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │ Gate 1   │  │ Gate 2   │  │ Gate 3   │  │ VIP Gate │        │
│  │ (iOS)    │  │ (Android)│  │ (iOS)    │  │ (Android)│        │
│  └─────┬────┘  └─────┬────┘  └─────┬────┘  └─────┬────┘        │
└────────┼─────────────┼─────────────┼─────────────┼──────────────┘
         │             │             │             │
         └─────────────┴─────────────┴─────────────┘
                       │
                       │ HTTPS (TLS 1.3)
                       │
┌──────────────────────▼──────────────────────────────────────────┐
│                   SCANNER API (EXPRESS.JS)                       │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Middleware Stack                                           │ │
│  │  ├─ CORS                                                   │ │
│  │  ├─ Helmet (Security Headers)                             │ │
│  │  ├─ Body Parser                                           │ │
│  │  ├─ Authentication                                        │ │
│  │  └─ Rate Limiting                                         │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Routes Layer                                               │ │
│  │  ├─ /api/scanner/verify-and-scan (POST)                   │ │
│  │  ├─ /api/scanner/verify-only (POST)                       │ │
│  │  ├─ /api/scanner/ticket-details (GET)                     │ │
│  │  ├─ /api/scanner/scan-history (GET)                       │ │
│  │  ├─ /api/scanner/batch-stats (GET)                        │ │
│  │  ├─ /api/scanner/manual-entry (POST)                      │ │
│  │  └─ /api/scanner/undo-scan (POST)                         │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Services Layer                                             │ │
│  │  ├─ QRService (HMAC verification)                         │ │
│  │  ├─ TicketService (DB operations)                         │ │
│  │  └─ ScanService (History & stats)                         │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Utils Layer                                                │ │
│  │  ├─ Supabase Client (Connection pooling)                  │ │
│  │  ├─ Crypto Utils (HMAC, timing-safe compare)             │ │
│  │  └─ Logger (Structured logging)                           │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────┬───────────────────────────────────────────┘
                       │
                       │ Supabase Client SDK
                       │ (Connection Pool: 10 connections)
                       │
┌──────────────────────▼──────────────────────────────────────────┐
│                   SUPABASE POSTGRESQL                            │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Tables                                                     │ │
│  │  ├─ bulk_ticket_batches (Event info)                      │ │
│  │  ├─ bulk_tickets (Ticket data) ← Primary table            │ │
│  │  ├─ bulk_ticket_scans (Audit log) ← Scan history          │ │
│  │  └─ bulk_ticket_generation_logs (Generation history)      │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Functions                                                  │ │
│  │  └─ verify_and_use_ticket() ← Atomic verification         │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Indexes (for performance)                                  │ │
│  │  ├─ idx_bulk_tickets_ticket_number                        │ │
│  │  ├─ idx_bulk_tickets_qr_code                              │ │
│  │  ├─ idx_bulk_tickets_valid_used                           │ │
│  │  └─ idx_bulk_ticket_scans_ticket                          │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘

READ THIS DIAGRAM:
1. Scanner apps at gates send HTTPS requests
2. API processes through middleware (auth, rate limit)
3. Routes handle business logic
4. Services interact with database
5. PostgreSQL stores and retrieves data with indexes
6. Database function ensures atomic operations
```

---

## ⏱️ Response Time Breakdown

```
┌─────────────────────────────────────────────────────────────────┐
│              TYPICAL RESPONSE TIME: ~300-500ms                   │
└─────────────────────────────────────────────────────────────────┘

USER SCANS QR CODE
    ↓
┌───────────────────────┐ ⏱️ ~50-100ms
│ Network to API        │ (depends on connection)
└───────┬───────────────┘
        ↓
┌───────────────────────┐ ⏱️ ~10ms
│ Middleware Processing │ (auth + rate limit)
└───────┬───────────────┘
        ↓
┌───────────────────────┐ ⏱️ ~5ms
│ HMAC Verification     │ (CPU-bound, very fast)
└───────┬───────────────┘
        ↓
┌───────────────────────┐ ⏱️ ~100-200ms
│ Database Query        │ (main latency)
│ - Row lock            │
│ - Status check        │
│ - Update ticket       │
│ - Insert log          │
└───────┬───────────────┘
        ↓
┌───────────────────────┐ ⏱️ ~5ms
│ Response Building     │
└───────┬───────────────┘
        ↓
┌───────────────────────┐ ⏱️ ~50-100ms
│ Network to App        │
└───────┬───────────────┘
        ↓
    RESULT SHOWN

TOTAL: ~220-420ms average
TARGET: < 500ms (✓ achieved)

OPTIMIZATION OPPORTUNITIES:
- Database: Already optimized with indexes
- Network: Use same region for API and DB
- Connection Pool: Already configured (10 connections)
- Caching: Future enhancement for batch info
```

---

## 🎯 Decision Tree

```
┌─────────────────────────────────────────────────────────────────┐
│                    SCAN RESULT DECISION TREE                     │
└─────────────────────────────────────────────────────────────────┘

                        TICKET SCANNED
                             │
                             ▼
                   ┌─────────────────┐
                   │ Valid Signature?│
                   └────┬────────┬───┘
                        │        │
                       YES       NO
                        │        └──► 🔴 DENY: "signature_mismatch"
                        │             (Fake ticket detected)
                        ▼
                   ┌─────────────────┐
                   │ Ticket Exists?  │
                   └────┬────────┬───┘
                        │        │
                       YES       NO
                        │        └──► 🟡 DENY: "not_found"
                        │             (Manual verification needed)
                        ▼
                   ┌─────────────────┐
                   │ Ticket Valid?   │
                   │ (is_valid=true) │
                   └────┬────────┬───┘
                        │        │
                       YES       NO
                        │        └──► 🔴 DENY: "invalid"
                        │             (Ticket canceled by vendor)
                        ▼
                   ┌─────────────────┐
                   │ Already Used?   │
                   │ (is_used=true)  │
                   └────┬────────┬───┘
                        │        │
                        NO      YES
                        │        └──► 🔴 DENY: "already_used"
                        │             (Show previous scan time)
                        ▼
                   ┌─────────────────┐
                   │ Mark as Used    │
                   │ + Log Scan      │
                   └────────┬────────┘
                            │
                            ▼
                    🟢 ALLOW ENTRY
                    "valid_unused"

RESULT COLORS:
🟢 Green = Allow Entry (valid_unused)
🔴 Red = Deny Entry (already_used, invalid, signature_mismatch)
🟡 Yellow = Manual Check (not_found)
```

---

**Use these diagrams to understand and explain the system! 📊**
