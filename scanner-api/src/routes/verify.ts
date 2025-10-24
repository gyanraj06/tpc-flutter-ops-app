import { Router, Response } from 'express';
import { QRService } from '../services/qrService';
import { TicketService } from '../services/ticketService';
import { ScanService } from '../services/scanService';
import { logger } from '../utils/logger';
import { asyncHandler } from '../middleware/errorHandler';
import { AuthenticatedRequest } from '../middleware/auth';
import { VerifyScanRequest, VerifyScanResponse, ScanResult } from '../types/scanner.types';

const router = Router();

// Lazy initialization - services created on first request
const getServices = () => ({
  qrService: new QRService(),
  ticketService: new TicketService(),
  scanService: new ScanService()
});

/**
 * POST /api/scanner/verify-and-scan
 * Primary endpoint for entry scanning - verifies QR code and marks ticket as used
 */
router.post(
  '/verify-and-scan',
  asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
    const startTime = Date.now();
    const scanTime = new Date().toISOString();

    try {
      const {
        qrData,
        signature,
        location,
        markAsUsed = true,
      }: VerifyScanRequest = req.body;

      const scannerId = req.scannerId!;
      const scannerName = req.scannerName || req.body.scannerName;

      // Validate request
      if (!qrData || !signature) {
        logger.warn('Invalid request - missing qrData or signature', { scannerId });
        res.status(400).json({
          success: false,
          error: 'invalid_request',
          message: 'Missing required fields: qrData and signature',
          timestamp: scanTime,
        });
        return;
      }

      logger.info('Scan request received', {
        scannerId,
        scannerName,
        location,
        markAsUsed,
        qrDataLength: qrData.length,
      });

      // Initialize services
      const { qrService, ticketService, scanService } = getServices();

      // Step 1: Verify QR signature
      const qrVerification = await qrService.verifyQRCode(qrData, signature);

      if (!qrVerification.isValid) {
        const response: VerifyScanResponse = {
          success: true,
          result: ScanResult.SIGNATURE_MISMATCH,
          message: 'QR code signature is invalid (possible forgery)',
          allowEntry: false,
          scanTime,
        };

        logger.warn('QR signature mismatch', { scannerId, location });
        res.json(response);
        return;
      }

      const { ticketNumber, batchId } = qrVerification.data!;

      // Step 2: Verify and mark ticket as used (if markAsUsed is true)
      let verification;

      if (markAsUsed) {
        verification = await ticketService.markTicketAsUsed(
          ticketNumber,
          scannerId,
          scannerName,
          location
        );
      } else {
        verification = await ticketService.verifyTicketStatus(ticketNumber);

        // Log verify-only scan
        if (verification.ticket) {
          await scanService.logScan(
            verification.ticket.id,
            verification.ticket.batch_id,
            'verify_only',
            scannerName || scannerId,
            location ? `Verify only at ${location}` : 'Verify only'
          );
        }
      }

      // Step 3: Build response
      const response: VerifyScanResponse = {
        success: true,
        result: verification.result,
        message: verification.message,
        allowEntry: verification.allowEntry,
        scanTime,
      };

      // Add ticket info if available
      if (verification.ticket) {
        response.ticket = {
          ticketNumber: verification.ticket.ticket_number,
          customerName: verification.ticket.customer_name,
          email: verification.ticket.email,
          phoneNumber: verification.ticket.phone_number,
          eventDate: verification.ticket.event_date,
          ticketPrice: verification.ticket.ticket_price,
          usedAt: verification.ticket.used_at || undefined,
        };

        response.batch = {
          eventTitle: verification.ticket.batch.event_title,
          venue: verification.ticket.batch.venue,
        };
      }

      const duration = Date.now() - startTime;
      logger.info('Scan completed', {
        scannerId,
        ticketNumber,
        result: verification.result,
        allowEntry: verification.allowEntry,
        duration: `${duration}ms`,
      });

      res.json(response);
    } catch (error) {
      logger.error('Error processing scan', {
        scannerId: req.scannerId,
        error: error instanceof Error ? error.message : 'Unknown error',
      });

      res.status(500).json({
        success: false,
        error: 'database_error',
        message: 'Failed to process scan request',
        details: process.env.NODE_ENV === 'development' ? (error instanceof Error ? error.message : 'Unknown error') : undefined,
        timestamp: scanTime,
      });
    }
  })
);

/**
 * POST /api/scanner/verify-only
 * Verify ticket WITHOUT marking as used (preview mode)
 */
router.post(
  '/verify-only',
  asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
    // Reuse verify-and-scan with markAsUsed = false
    req.body.markAsUsed = false;

    // Forward to verify-and-scan handler
    const verifyAndScanHandler = router.stack.find(
      (layer) => layer.route?.path === '/verify-and-scan'
    )?.route?.stack[0].handle;

    if (verifyAndScanHandler) {
      return verifyAndScanHandler(req, res, () => {});
    }

    res.status(500).json({
      success: false,
      error: 'internal_error',
      message: 'Failed to process verification',
      timestamp: new Date().toISOString(),
    });
  })
);

export default router;
