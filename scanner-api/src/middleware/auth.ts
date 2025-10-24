import { Request, Response, NextFunction } from 'express';
import { logger } from '../utils/logger';

/**
 * Scanner authentication middleware
 * Validates scanner API key and device ID
 */

export interface AuthenticatedRequest extends Request {
  scannerId?: string;
  scannerName?: string;
}

export const authenticateScanner = (req: AuthenticatedRequest, res: Response, next: NextFunction): void => {
  try {
    // Get API key from Authorization header
    const authHeader = req.headers.authorization;
    const apiKey = authHeader?.replace('Bearer ', '');

    // Get scanner ID from custom header
    const scannerId = req.headers['x-scanner-id'] as string;

    // Validate API key
    const validApiKey = process.env.SCANNER_API_KEY;

    if (!validApiKey) {
      logger.error('SCANNER_API_KEY not configured');
      res.status(500).json({
        success: false,
        error: 'server_configuration_error',
        message: 'Server configuration error',
        timestamp: new Date().toISOString(),
      });
      return;
    }

    if (!apiKey || apiKey !== validApiKey) {
      logger.warn('Invalid API key', { scannerId, ip: req.ip });
      res.status(401).json({
        success: false,
        error: 'unauthorized',
        message: 'Invalid API key',
        timestamp: new Date().toISOString(),
      });
      return;
    }

    if (!scannerId) {
      logger.warn('Missing scanner ID', { ip: req.ip });
      res.status(400).json({
        success: false,
        error: 'invalid_request',
        message: 'Scanner ID is required in X-Scanner-ID header',
        timestamp: new Date().toISOString(),
      });
      return;
    }

    // Attach scanner info to request
    req.scannerId = scannerId;
    req.scannerName = req.headers['x-scanner-name'] as string;

    logger.debug('Scanner authenticated', { scannerId, scannerName: req.scannerName });

    next();
  } catch (error) {
    logger.error('Authentication error', { error: error instanceof Error ? error.message : 'Unknown error' });
    res.status(500).json({
      success: false,
      error: 'authentication_error',
      message: 'Authentication failed',
      timestamp: new Date().toISOString(),
    });
  }
};

/**
 * Admin authentication middleware (for sensitive operations)
 */
export const authenticateAdmin = (req: Request, res: Response, next: NextFunction): void => {
  try {
    const authHeader = req.headers.authorization;
    const apiKey = authHeader?.replace('Bearer ', '');

    const adminApiKey = process.env.ADMIN_API_KEY;

    if (!adminApiKey) {
      logger.error('ADMIN_API_KEY not configured');
      res.status(500).json({
        success: false,
        error: 'server_configuration_error',
        message: 'Server configuration error',
        timestamp: new Date().toISOString(),
      });
      return;
    }

    if (!apiKey || apiKey !== adminApiKey) {
      logger.warn('Invalid admin API key', { ip: req.ip });
      res.status(403).json({
        success: false,
        error: 'forbidden',
        message: 'Admin access required',
        timestamp: new Date().toISOString(),
      });
      return;
    }

    logger.debug('Admin authenticated', { ip: req.ip });

    next();
  } catch (error) {
    logger.error('Admin authentication error', { error: error instanceof Error ? error.message : 'Unknown error' });
    res.status(500).json({
      success: false,
      error: 'authentication_error',
      message: 'Authentication failed',
      timestamp: new Date().toISOString(),
    });
  }
};
