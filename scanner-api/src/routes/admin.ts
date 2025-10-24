import { Router, Response } from 'express';
import { TicketService } from '../services/ticketService';
import { logger } from '../utils/logger';
import { asyncHandler } from '../middleware/errorHandler';
import { AuthenticatedRequest } from '../middleware/auth';
import { ManualEntryRequest, UndoScanRequest } from '../types/scanner.types';

const router = Router();
const getTicketService = () => new TicketService();

/**
 * POST /api/scanner/manual-entry
 * Manually mark a ticket as used (for cases where QR code is damaged/not working)
 */
router.post(
  '/manual-entry',
  asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
    try {
      const { ticketNumber, reason }: ManualEntryRequest = req.body;
      const scannerId = req.scannerId!;
      const scannerName = req.scannerName || req.body.scannerName;

      if (!ticketNumber || !reason) {
        res.status(400).json({
          success: false,
          error: 'invalid_request',
          message: 'Missing required fields: ticketNumber and reason',
          timestamp: new Date().toISOString(),
        });
        return;
      }

      logger.info('Manual entry request', { ticketNumber, scannerId, reason });

      const ticketService = getTicketService();
      const result = await ticketService.manualEntry(
        ticketNumber,
        scannerId,
        reason,
        scannerName
      );

      if (!result.allowEntry) {
        res.status(400).json({
          success: true,
          result: result.result,
          message: result.message,
          allowEntry: false,
          ticket: result.ticket ? {
            ticketNumber: result.ticket.ticket_number,
            customerName: result.ticket.customer_name,
            usedAt: result.ticket.used_at,
          } : undefined,
          timestamp: new Date().toISOString(),
        });
        return;
      }

      res.json({
        success: true,
        message: 'Ticket marked as used manually',
        ticket: {
          ticketNumber: result.ticket!.ticket_number,
          customerName: result.ticket!.customer_name,
          usedAt: new Date().toISOString(),
        },
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      logger.error('Error processing manual entry', {
        error: error instanceof Error ? error.message : 'Unknown error',
      });

      res.status(500).json({
        success: false,
        error: 'database_error',
        message: 'Failed to process manual entry',
        timestamp: new Date().toISOString(),
      });
    }
  })
);

/**
 * POST /api/scanner/undo-scan
 * Undo a ticket scan (mark as unused again) - Admin only
 */
router.post(
  '/undo-scan',
  asyncHandler(async (req: AuthenticatedRequest, res: Response) => {
    try {
      const { ticketNumber, adminId, reason }: UndoScanRequest = req.body;

      if (!ticketNumber || !adminId || !reason) {
        res.status(400).json({
          success: false,
          error: 'invalid_request',
          message: 'Missing required fields: ticketNumber, adminId, and reason',
          timestamp: new Date().toISOString(),
        });
        return;
      }

      logger.info('Undo scan request', { ticketNumber, adminId, reason });

      const ticketService = getTicketService();
      const result = await ticketService.undoScan(ticketNumber, adminId, reason);

      if (result.result === 'not_found') {
        res.status(404).json({
          success: false,
          error: 'not_found',
          message: result.message,
          timestamp: new Date().toISOString(),
        });
        return;
      }

      if (result.result === 'invalid') {
        res.status(400).json({
          success: false,
          error: 'invalid_request',
          message: result.message,
          timestamp: new Date().toISOString(),
        });
        return;
      }

      res.json({
        success: true,
        message: 'Ticket scan undone successfully',
        ticket: {
          ticketNumber: result.ticket!.ticket_number,
          customerName: result.ticket!.customer_name,
          isUsed: false,
          usedAt: null,
        },
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      logger.error('Error undoing scan', {
        error: error instanceof Error ? error.message : 'Unknown error',
      });

      res.status(500).json({
        success: false,
        error: 'database_error',
        message: 'Failed to undo scan',
        timestamp: new Date().toISOString(),
      });
    }
  })
);

export default router;
