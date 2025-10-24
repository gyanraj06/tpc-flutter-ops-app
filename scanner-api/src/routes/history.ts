import { Router, Request, Response } from 'express';
import { ScanService } from '../services/scanService';
import { logger } from '../utils/logger';
import { asyncHandler } from '../middleware/errorHandler';
import { ScanHistoryQuery } from '../types/scanner.types';

const router = Router();
const getScanService = () => new ScanService();

/**
 * GET /api/scanner/scan-history
 * Fetch scan history for a scanner or event
 */
router.get(
  '/scan-history',
  asyncHandler(async (req: Request, res: Response) => {
    try {
      const query: ScanHistoryQuery = {
        scannerId: req.query.scannerId as string,
        batchId: req.query.batchId as string,
        limit: req.query.limit ? parseInt(req.query.limit as string) : 50,
        offset: req.query.offset ? parseInt(req.query.offset as string) : 0,
        from: req.query.from as string,
        to: req.query.to as string,
      };

      logger.info('Fetching scan history', query);

      const scanService = getScanService();
      const result = await scanService.getScanHistory(query);

      const page = Math.floor((query.offset || 0) / (query.limit || 50)) + 1;

      res.json({
        success: true,
        scans: result.scans,
        total: result.total,
        page,
        limit: query.limit,
      });
    } catch (error) {
      logger.error('Error fetching scan history', {
        error: error instanceof Error ? error.message : 'Unknown error',
      });

      res.status(500).json({
        success: false,
        error: 'database_error',
        message: 'Failed to fetch scan history',
        timestamp: new Date().toISOString(),
      });
    }
  })
);

export default router;
