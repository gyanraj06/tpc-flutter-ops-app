import { Router, Request, Response } from 'express';
import { TicketService } from '../services/ticketService';
import { logger } from '../utils/logger';
import { asyncHandler } from '../middleware/errorHandler';

const router = Router();
const getTicketService = () => new TicketService();

/**
 * GET /api/scanner/ticket-details
 * Fetch full ticket details by ticket number (for manual lookup)
 */
router.get(
  '/ticket-details',
  asyncHandler(async (req: Request, res: Response) => {
    try {
      const { ticketNumber } = req.query;

      if (!ticketNumber || typeof ticketNumber !== 'string') {
        res.status(400).json({
          success: false,
          error: 'invalid_request',
          message: 'Ticket number is required',
          timestamp: new Date().toISOString(),
        });
        return;
      }

      logger.info('Fetching ticket details', { ticketNumber });

      const ticketService = getTicketService();
      const result = await ticketService.getTicketDetails(ticketNumber);

      if (!result) {
        res.status(404).json({
          success: false,
          error: 'not_found',
          message: 'Ticket not found',
          timestamp: new Date().toISOString(),
        });
        return;
      }

      const { ticket, scanHistory } = result;

      res.json({
        success: true,
        ticket: {
          id: ticket.id,
          ticketNumber: ticket.ticket_number,
          customerName: ticket.customer_name,
          email: ticket.email,
          phoneNumber: ticket.phone_number,
          eventDate: ticket.event_date,
          ticketPrice: ticket.ticket_price,
          isValid: ticket.is_valid,
          isUsed: ticket.is_used,
          usedAt: ticket.used_at,
          pdfUrl: ticket.pdf_url,
        },
        batch: {
          eventTitle: ticket.batch.event_title,
          venue: ticket.batch.venue,
          primaryColor: ticket.batch.primary_color,
          secondaryColor: ticket.batch.secondary_color,
          accentColor: ticket.batch.accent_color,
        },
        scanHistory: scanHistory.map((scan) => ({
          scannedAt: scan.scanned_at,
          scannedBy: scan.scanned_by,
          scanResult: scan.scan_result,
          scanNotes: scan.scan_notes,
        })),
      });
    } catch (error) {
      logger.error('Error fetching ticket details', {
        error: error instanceof Error ? error.message : 'Unknown error',
      });

      res.status(500).json({
        success: false,
        error: 'database_error',
        message: 'Failed to fetch ticket details',
        timestamp: new Date().toISOString(),
      });
    }
  })
);

export default router;
