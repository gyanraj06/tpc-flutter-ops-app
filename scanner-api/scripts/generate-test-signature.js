#!/usr/bin/env node

/**
 * Generate HMAC-SHA256 signature for testing QR codes
 * Usage: node scripts/generate-test-signature.js
 */

const crypto = require('crypto');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

console.log('=== QR Code Signature Generator ===\n');

rl.question('Enter QR Secret Key (from .env): ', (secretKey) => {
  if (!secretKey) {
    console.error('Error: Secret key is required');
    rl.close();
    process.exit(1);
  }

  rl.question('Enter Ticket Number (e.g., MTK1001): ', (ticketNumber) => {
    rl.question('Enter Batch ID (UUID): ', (batchId) => {
      rl.question('Enter Customer Name: ', (customerName) => {
        rl.question('Enter Event Date (DD/MM/YYYY): ', (eventDate) => {
          // Build QR data
          const qrData = JSON.stringify({
            ticketNumber,
            batchId,
            customerName,
            eventDate,
          });

          // Generate HMAC signature
          const hmac = crypto.createHmac('sha256', secretKey);
          hmac.update(qrData);
          const signature = hmac.digest('hex');

          console.log('\n=== Generated QR Code Data ===\n');
          console.log('QR Data:');
          console.log(qrData);
          console.log('\nSignature:');
          console.log(signature);

          console.log('\n=== cURL Test Command ===\n');
          console.log(`curl -X POST http://localhost:3000/api/scanner/verify-and-scan \\
  -H "Content-Type: application/json" \\
  -H "Authorization: Bearer YOUR_SCANNER_API_KEY" \\
  -H "X-Scanner-ID: test-scanner-01" \\
  -d '{
    "qrData": ${JSON.stringify(qrData)},
    "signature": "${signature}",
    "location": "Test Location",
    "markAsUsed": false
  }'`);

          console.log('\n=== Postman/Insomnia JSON Body ===\n');
          console.log(JSON.stringify({
            qrData,
            signature,
            location: 'Test Location',
            markAsUsed: false,
          }, null, 2));

          rl.close();
        });
      });
    });
  });
});
