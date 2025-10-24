import { verifyQRSignature, parseQRData, QRCodeData } from '../utils/crypto';
import { logger } from '../utils/logger';

/**
 * Service for QR code verification and validation
 */

export interface QRVerificationResult {
  isValid: boolean;
  error?: string;
  data?: QRCodeData;
}

export class QRService {
  private secretKey: string;

  constructor() {
    this.secretKey = process.env.QR_SECRET_KEY || '';

    if (!this.secretKey) {
      throw new Error('QR_SECRET_KEY environment variable is not set');
    }
  }

  /**
   * Verify QR code signature and parse data
   */
  async verifyQRCode(qrData: string, signature: string): Promise<QRVerificationResult> {
    try {
      // Step 1: Verify HMAC signature
      logger.debug('Verifying QR signature', { qrDataLength: qrData.length, signatureLength: signature.length });

      const isSignatureValid = verifyQRSignature(qrData, signature, this.secretKey);

      if (!isSignatureValid) {
        logger.warn('QR signature verification failed - possible forgery');
        return {
          isValid: false,
          error: 'signature_mismatch',
        };
      }

      // Step 2: Parse QR data
      logger.debug('QR signature verified, parsing data');
      const parsedData = parseQRData(qrData);

      logger.info('QR code verified successfully', {
        ticketNumber: parsedData.ticketNumber,
        batchId: parsedData.batchId,
      });

      return {
        isValid: true,
        data: parsedData,
      };
    } catch (error) {
      logger.error('Error verifying QR code', { error: error instanceof Error ? error.message : 'Unknown error' });
      return {
        isValid: false,
        error: 'invalid_qr_format',
      };
    }
  }
}
