import { Router, Request, Response } from 'express';
import { ScanService } from '../services/scanService';
import { getSupabaseClient } from '../utils/supabase';
import { logger } from '../utils/logger';
import { asyncHandler } from '../middleware/errorHandler';

const router = Router();
const getScanService = () => new ScanService();
const supabase = getSupabaseClient();

/**
 * GET /api/scanner/batch-stats
 * Get real-time statistics for an event batch
 */
router.get(
  '/batch-stats',
  asyncHandler(async (req: Request, res: Response) => {
    try {
      const { batchId } = req.query;

      if (!batchId || typeof batchId !== 'string') {
        res.status(400).json({
          success: false,
          error: 'invalid_request',
          message: 'Batch ID is required',
          timestamp: new Date().toISOString(),
        });
        return;
      }

      logger.info('Fetching batch statistics', { batchId });

      const scanService = getScanService();
      const stats = await scanService.getBatchStats(batchId);

      if (!stats) {
        res.status(404).json({
          success: false,
          error: 'not_found',
          message: 'Batch not found',
          timestamp: new Date().toISOString(),
        });
        return;
      }

      // Get batch info
      const { data: batch } = await supabase
        .from('bulk_ticket_batches')
        .select('event_title, venue, event_date:bulk_tickets(event_date)')
        .eq('id', batchId)
        .single();

      res.json({
        success: true,
        batchId,
        eventTitle: batch?.event_title || 'Unknown',
        venue: batch?.venue || 'Unknown',
        stats,
      });
    } catch (error) {
      logger.error('Error fetching batch statistics', {
        error: error instanceof Error ? error.message : 'Unknown error',
      });

      res.status(500).json({
        success: false,
        error: 'database_error',
        message: 'Failed to fetch batch statistics',
        timestamp: new Date().toISOString(),
      });
    }
  })
);

export default router;
