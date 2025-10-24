import crypto from 'crypto';

/**
 * Verify QR code HMAC signature using timing-safe comparison
 * @param qrData - The JSON string data from QR code
 * @param signature - The HMAC signature from QR code
 * @param secretKey - The secret key used for HMAC generation
 * @returns boolean indicating if signature is valid
 */
export const verifyQRSignature = (
  qrData: string,
  signature: string,
  secretKey: string
): boolean => {
  try {
    // Generate expected signature
    const hmac = crypto.createHmac('sha256', secretKey);
    hmac.update(qrData);
    const expectedSignature = hmac.digest('hex');

    // Use timing-safe comparison to prevent timing attacks
    const expectedBuffer = Buffer.from(expectedSignature, 'hex');
    const receivedBuffer = Buffer.from(signature, 'hex');

    // Ensure both buffers are same length
    if (expectedBuffer.length !== receivedBuffer.length) {
      return false;
    }

    return crypto.timingSafeEqual(expectedBuffer, receivedBuffer);
  } catch (error) {
    console.error('Error verifying QR signature:', error);
    return false;
  }
};

/**
 * Parse QR code data
 * @param qrData - The JSON string from QR code
 * @returns Parsed QR data object
 */
export interface QRCodeData {
  ticketNumber: string;
  batchId: string;
  customerName: string;
  eventDate: string;
}

export const parseQRData = (qrData: string): QRCodeData => {
  try {
    const parsed = JSON.parse(qrData);

    if (!parsed.ticketNumber || !parsed.batchId || !parsed.customerName || !parsed.eventDate) {
      throw new Error('Missing required fields in QR code data');
    }

    return {
      ticketNumber: parsed.ticketNumber,
      batchId: parsed.batchId,
      customerName: parsed.customerName,
      eventDate: parsed.eventDate,
    };
  } catch (error) {
    throw new Error(`Invalid QR code data format: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
};

/**
 * Generate HMAC signature for testing purposes
 * @param qrData - The JSON string data
 * @param secretKey - The secret key
 * @returns HMAC signature as hex string
 */
export const generateQRSignature = (qrData: string, secretKey: string): string => {
  const hmac = crypto.createHmac('sha256', secretKey);
  hmac.update(qrData);
  return hmac.digest('hex');
};
