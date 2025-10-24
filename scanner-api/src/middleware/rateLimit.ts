import rateLimit from 'express-rate-limit';
import { logger } from '../utils/logger';

/**
 * Rate limiting middleware configurations
 */

// Standard rate limit for verification endpoints
export const verifyRateLimit = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '60000'), // 1 minute default
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100'), // 100 requests per minute
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: 'rate_limit_exceeded',
    message: 'Too many scan requests, please try again later',
    timestamp: new Date().toISOString(),
  },
  handler: (req, res) => {
    logger.warn('Rate limit exceeded', {
      ip: req.ip,
      scannerId: req.headers['x-scanner-id'],
      path: req.path,
    });

    res.status(429).json({
      success: false,
      error: 'rate_limit_exceeded',
      message: 'Too many scan requests, please try again later',
      timestamp: new Date().toISOString(),
    });
  },
  skip: (req) => {
    // Skip rate limiting in development
    return process.env.NODE_ENV === 'development';
  },
});

// Stricter rate limit for history/stats endpoints
export const historyRateLimit = rateLimit({
  windowMs: 60000, // 1 minute
  max: 20, // 20 requests per minute
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: 'rate_limit_exceeded',
    message: 'Too many requests, please try again later',
    timestamp: new Date().toISOString(),
  },
  skip: (req) => {
    return process.env.NODE_ENV === 'development';
  },
});

// Very strict rate limit for admin operations
export const adminRateLimit = rateLimit({
  windowMs: 60000, // 1 minute
  max: 10, // 10 requests per minute
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: 'rate_limit_exceeded',
    message: 'Too many admin requests, please try again later',
    timestamp: new Date().toISOString(),
  },
  handler: (req, res) => {
    logger.warn('Admin rate limit exceeded', {
      ip: req.ip,
      path: req.path,
    });

    res.status(429).json({
      success: false,
      error: 'rate_limit_exceeded',
      message: 'Too many admin requests, please try again later',
      timestamp: new Date().toISOString(),
    });
  },
  skip: (req) => {
    return process.env.NODE_ENV === 'development';
  },
});
