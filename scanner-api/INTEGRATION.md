# Scanner App Integration Guide

Guide for integrating the TPC Ops mobile scanner app with the backend API.

## Overview

The scanner app (React Native/Flutter) will:
1. Scan QR codes using device camera
2. Extract QR data and signature from scanned code
3. Send to backend API for verification
4. Display color-coded result (green/red/yellow)
5. Log scans locally for offline support (future)

---

## QR Code Format

The QR code contains a JSON string with two parts:

### Structure

```json
{
  "data": "{\"ticketNumber\":\"MTK1001\",\"batchId\":\"550e8400\",\"customerName\":\"John Doe\",\"eventDate\":\"15/01/2026\"}",
  "signature": "abc123def456789abcdef..."
}
```

**Note:** The main ticket generation system should encode both `data` and `signature` together in the QR code.

---

## API Integration

### Base Configuration

```typescript
// config.ts
export const API_CONFIG = {
  baseURL: 'https://your-api-url.com',
  apiKey: 'scanner_api_key_12345',
  scannerId: 'scanner-01', // Unique per device
  scannerName: 'Gate 1 - Main Entrance', // Human-readable name
  timeout: 10000, // 10 seconds
};
```

### API Client Setup

**TypeScript/JavaScript:**

```typescript
// api/scannerClient.ts
import axios from 'axios';
import { API_CONFIG } from '../config';

const apiClient = axios.create({
  baseURL: API_CONFIG.baseURL,
  timeout: API_CONFIG.timeout,
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${API_CONFIG.apiKey}`,
    'X-Scanner-ID': API_CONFIG.scannerId,
    'X-Scanner-Name': API_CONFIG.scannerName,
  },
});

// Add response interceptor for error handling
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error('API Error:', error.response?.data || error.message);
    throw error;
  }
);

export default apiClient;
```

---

## Main Scanning Flow

### 1. Scan QR Code

```typescript
// services/qrScanner.ts
import { Camera } from 'react-native-vision-camera';

async function scanQRCode(): Promise<QRCodeData> {
  // Use your camera library to scan QR code
  const scannedData = await Camera.scanQRCode();

  // Parse the QR code content
  const qrContent = JSON.parse(scannedData);

  return {
    qrData: qrContent.data,
    signature: qrContent.signature,
  };
}
```

### 2. Verify with Backend

```typescript
// services/ticketVerification.ts
import apiClient from '../api/scannerClient';

interface VerifyRequest {
  qrData: string;
  signature: string;
  location?: string;
  markAsUsed?: boolean;
}

interface VerifyResponse {
  success: boolean;
  result: 'valid_unused' | 'already_used' | 'invalid' | 'not_found' | 'signature_mismatch';
  message: string;
  allowEntry: boolean;
  ticket?: {
    ticketNumber: string;
    customerName: string;
    email?: string;
    phoneNumber?: string;
    eventDate?: string;
    ticketPrice?: number;
    usedAt?: string;
  };
  batch?: {
    eventTitle: string;
    venue: string;
  };
  scanTime: string;
}

export async function verifyTicket(
  qrData: string,
  signature: string,
  location?: string,
  markAsUsed: boolean = true
): Promise<VerifyResponse> {
  try {
    const response = await apiClient.post<VerifyResponse>(
      '/api/scanner/verify-and-scan',
      {
        qrData,
        signature,
        location,
        markAsUsed,
      }
    );

    return response.data;
  } catch (error) {
    // Handle network errors
    if (error.response) {
      // API returned an error response
      return error.response.data;
    } else {
      // Network error or timeout
      throw new Error('Network error - please check your connection');
    }
  }
}
```

### 3. Display Result

```typescript
// screens/ScanResultScreen.tsx
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

interface ScanResultProps {
  result: VerifyResponse;
}

export const ScanResultScreen: React.FC<ScanResultProps> = ({ result }) => {
  // Determine UI color based on result
  const getResultStyle = () => {
    switch (result.result) {
      case 'valid_unused':
        return styles.success; // Green
      case 'already_used':
      case 'invalid':
      case 'signature_mismatch':
        return styles.error; // Red
      case 'not_found':
        return styles.warning; // Yellow
      default:
        return styles.default;
    }
  };

  const getResultMessage = () => {
    switch (result.result) {
      case 'valid_unused':
        return 'ALLOW ENTRY ✓';
      case 'already_used':
        return 'TICKET ALREADY USED ✗';
      case 'invalid':
        return 'TICKET INVALID ✗';
      case 'signature_mismatch':
        return 'FAKE TICKET DETECTED ⚠';
      case 'not_found':
        return 'TICKET NOT FOUND ⚠';
      default:
        return 'UNKNOWN ERROR';
    }
  };

  return (
    <View style={[styles.container, getResultStyle()]}>
      <Text style={styles.resultMessage}>{getResultMessage()}</Text>

      {result.ticket && (
        <View style={styles.ticketInfo}>
          <Text style={styles.ticketNumber}>{result.ticket.ticketNumber}</Text>
          <Text style={styles.customerName}>{result.ticket.customerName}</Text>
          {result.batch && (
            <>
              <Text style={styles.eventTitle}>{result.batch.eventTitle}</Text>
              <Text style={styles.venue}>{result.batch.venue}</Text>
            </>
          )}
          {result.ticket.usedAt && (
            <Text style={styles.usedAt}>
              Previously used: {new Date(result.ticket.usedAt).toLocaleString()}
            </Text>
          )}
        </View>
      )}

      <Text style={styles.message}>{result.message}</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  success: {
    backgroundColor: '#10b981', // Green
  },
  error: {
    backgroundColor: '#ef4444', // Red
  },
  warning: {
    backgroundColor: '#f59e0b', // Yellow
  },
  default: {
    backgroundColor: '#6b7280', // Gray
  },
  resultMessage: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 20,
    textAlign: 'center',
  },
  ticketInfo: {
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    padding: 20,
    borderRadius: 10,
    marginBottom: 20,
    width: '100%',
  },
  ticketNumber: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 10,
  },
  customerName: {
    fontSize: 20,
    color: '#fff',
    marginBottom: 10,
  },
  eventTitle: {
    fontSize: 18,
    color: '#fff',
    marginBottom: 5,
  },
  venue: {
    fontSize: 16,
    color: '#fff',
    marginBottom: 10,
  },
  usedAt: {
    fontSize: 14,
    color: '#fff',
    fontStyle: 'italic',
  },
  message: {
    fontSize: 16,
    color: '#fff',
    textAlign: 'center',
  },
});
```

---

## Complete Scanning Flow

```typescript
// screens/ScannerScreen.tsx
import React, { useState } from 'react';
import { View, Button, ActivityIndicator } from 'react-native';
import { scanQRCode } from '../services/qrScanner';
import { verifyTicket } from '../services/ticketVerification';
import { ScanResultScreen } from './ScanResultScreen';

export const ScannerScreen: React.FC = () => {
  const [isScanning, setIsScanning] = useState(false);
  const [isVerifying, setIsVerifying] = useState(false);
  const [result, setResult] = useState<VerifyResponse | null>(null);

  const handleScan = async () => {
    try {
      // Step 1: Scan QR code
      setIsScanning(true);
      const { qrData, signature } = await scanQRCode();
      setIsScanning(false);

      // Step 2: Verify with backend
      setIsVerifying(true);
      const verifyResult = await verifyTicket(
        qrData,
        signature,
        'Main Entrance', // Location
        true // Mark as used
      );
      setIsVerifying(false);

      // Step 3: Show result
      setResult(verifyResult);

      // Step 4: Play sound/vibration based on result
      if (verifyResult.allowEntry) {
        playSuccessSound();
        vibrate('success');
      } else {
        playErrorSound();
        vibrate('error');
      }

      // Step 5: Auto-reset after 5 seconds
      setTimeout(() => {
        setResult(null);
      }, 5000);

    } catch (error) {
      setIsScanning(false);
      setIsVerifying(false);

      // Show error
      setResult({
        success: false,
        result: 'not_found',
        message: error.message || 'Network error',
        allowEntry: false,
        scanTime: new Date().toISOString(),
      });
    }
  };

  if (result) {
    return <ScanResultScreen result={result} />;
  }

  return (
    <View>
      {isScanning && <ActivityIndicator size="large" />}
      {isVerifying && <ActivityIndicator size="large" />}

      <Button
        title="Scan Ticket"
        onPress={handleScan}
        disabled={isScanning || isVerifying}
      />
    </View>
  );
};
```

---

## Additional Features

### 1. Manual Ticket Lookup

```typescript
// services/ticketLookup.ts
export async function lookupTicket(ticketNumber: string) {
  const response = await apiClient.get(
    `/api/scanner/ticket-details?ticketNumber=${ticketNumber}`
  );
  return response.data;
}
```

### 2. Scan History

```typescript
// services/scanHistory.ts
export async function getScanHistory(limit: number = 50) {
  const response = await apiClient.get('/api/scanner/scan-history', {
    params: { limit },
  });
  return response.data;
}
```

### 3. Batch Statistics

```typescript
// services/batchStats.ts
export async function getBatchStats(batchId: string) {
  const response = await apiClient.get('/api/scanner/batch-stats', {
    params: { batchId },
  });
  return response.data;
}
```

### 4. Manual Entry (Damaged QR)

```typescript
// services/manualEntry.ts
export async function manualEntry(ticketNumber: string, reason: string) {
  const response = await apiClient.post('/api/scanner/manual-entry', {
    ticketNumber,
    reason,
  });
  return response.data;
}
```

---

## Error Handling

### Network Errors

```typescript
try {
  const result = await verifyTicket(qrData, signature);
} catch (error) {
  if (error.code === 'ECONNABORTED') {
    // Timeout
    showError('Request timed out - please try again');
  } else if (!error.response) {
    // No network connection
    showError('No internet connection');
    // Queue for offline sync
    queueOfflineScan(qrData, signature);
  } else {
    // API error
    showError(error.response.data.message);
  }
}
```

### Rate Limiting

```typescript
if (error.response?.status === 429) {
  showError('Too many requests - please wait a moment');
  // Implement exponential backoff
  await delay(5000);
  // Retry
}
```

---

## Offline Support (Future)

### 1. Queue Failed Scans

```typescript
// services/offlineQueue.ts
import AsyncStorage from '@react-native-async-storage/async-storage';

export async function queueOfflineScan(qrData: string, signature: string) {
  const queue = await AsyncStorage.getItem('offline_queue');
  const scans = queue ? JSON.parse(queue) : [];

  scans.push({
    qrData,
    signature,
    scannedAt: new Date().toISOString(),
    offlineId: generateUUID(),
  });

  await AsyncStorage.setItem('offline_queue', JSON.stringify(scans));
}
```

### 2. Sync When Online

```typescript
// services/offlineSync.ts
export async function syncOfflineScans() {
  const queue = await AsyncStorage.getItem('offline_queue');
  if (!queue) return;

  const scans = JSON.parse(queue);

  // Send to backend
  const response = await apiClient.post('/api/scanner/sync-offline-scans', {
    scans,
  });

  // Clear queue
  await AsyncStorage.removeItem('offline_queue');

  return response.data;
}
```

---

## Testing

### Unit Tests

```typescript
// __tests__/ticketVerification.test.ts
import { verifyTicket } from '../services/ticketVerification';

describe('Ticket Verification', () => {
  it('should verify valid ticket', async () => {
    const result = await verifyTicket(mockQRData, mockSignature);
    expect(result.allowEntry).toBe(true);
    expect(result.result).toBe('valid_unused');
  });

  it('should reject already used ticket', async () => {
    const result = await verifyTicket(usedQRData, mockSignature);
    expect(result.allowEntry).toBe(false);
    expect(result.result).toBe('already_used');
  });
});
```

### Integration Tests

```typescript
// __tests__/scanFlow.test.ts
import { render, fireEvent, waitFor } from '@testing-library/react-native';
import { ScannerScreen } from '../screens/ScannerScreen';

test('complete scan flow', async () => {
  const { getByText } = render(<ScannerScreen />);

  fireEvent.press(getByText('Scan Ticket'));

  await waitFor(() => {
    expect(getByText('ALLOW ENTRY ✓')).toBeTruthy();
  });
});
```

---

## Performance Optimization

### 1. Request Caching

```typescript
// Cache batch details to avoid repeated API calls
const batchCache = new Map<string, BatchInfo>();

async function getBatchInfo(batchId: string) {
  if (batchCache.has(batchId)) {
    return batchCache.get(batchId);
  }

  const info = await fetchBatchInfo(batchId);
  batchCache.set(batchId, info);

  return info;
}
```

### 2. Debouncing

```typescript
// Prevent rapid repeated scans
let lastScanTime = 0;
const MIN_SCAN_INTERVAL = 2000; // 2 seconds

function canScan(): boolean {
  const now = Date.now();
  if (now - lastScanTime < MIN_SCAN_INTERVAL) {
    return false;
  }
  lastScanTime = now;
  return true;
}
```

---

## Security Best Practices

1. **Store API Key Securely**: Use device keychain/keystore, not plain AsyncStorage
2. **Validate QR Data**: Always verify signature before using data
3. **HTTPS Only**: Never use HTTP in production
4. **Timeout Requests**: Set reasonable timeout (10 seconds)
5. **Rate Limit Client-Side**: Prevent abuse from compromised device
6. **Log Locally**: Keep local audit trail for disputes

---

## Troubleshooting

### Issue: Slow verification (> 2 seconds)

**Check:**
- Network latency
- API server location (use same region as Supabase)
- Device internet speed

**Solution:**
- Show loading indicator
- Implement timeout with retry

### Issue: Camera not scanning QR codes

**Check:**
- Camera permissions granted
- QR code has sufficient contrast
- Lighting conditions

**Solution:**
- Add manual entry option
- Improve camera focus logic

---

## Next Steps

1. Implement camera QR scanning
2. Integrate API client
3. Build result screens
4. Add offline queue
5. Test with real tickets
6. Deploy to TestFlight/Play Console

---

**Happy integrating! 📱**
