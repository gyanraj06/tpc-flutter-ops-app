// Load environment variables FIRST before any other imports
import dotenv from 'dotenv';
dotenv.config();

import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { logger } from './utils/logger';
import { errorHandler, notFoundHandler } from './middleware/errorHandler';
import { authenticateScanner, authenticateAdmin } from './middleware/auth';
import { verifyRateLimit, historyRateLimit, adminRateLimit } from './middleware/rateLimit';

// Import routes
import verifyRoutes from './routes/verify';
import ticketRoutes from './routes/tickets';
import historyRoutes from './routes/history';
import statsRoutes from './routes/stats';
import adminRoutes from './routes/admin';

// Validate required environment variables
const requiredEnvVars = [
  'VITE_SUPABASE_URL',
  'SUPABASE_SERVICE_ROLE_KEY',
  'QR_SECRET_KEY',
  'SCANNER_API_KEY',
];

const missingEnvVars = requiredEnvVars.filter((varName) => !process.env[varName]);

if (missingEnvVars.length > 0) {
  logger.error('Missing required environment variables', { missing: missingEnvVars });
  process.exit(1);
}

// Create Express app
const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  credentials: true,
}));

// Body parser
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging
app.use((req, res, next) => {
  logger.info('Incoming request', {
    method: req.method,
    path: req.path,
    ip: req.ip,
    userAgent: req.get('user-agent'),
  });
  next();
});

// Health check endpoint (no authentication required)
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
  });
});

// API version info
app.get('/api', (req, res) => {
  res.json({
    name: 'TPC Ops Scanner API',
    version: '1.0.0',
    description: 'Backend API for QR code ticket scanning',
    endpoints: {
      verification: '/api/scanner/verify-and-scan',
      verifyOnly: '/api/scanner/verify-only',
      ticketDetails: '/api/scanner/ticket-details',
      scanHistory: '/api/scanner/scan-history',
      batchStats: '/api/scanner/batch-stats',
      manualEntry: '/api/scanner/manual-entry',
      undoScan: '/api/scanner/undo-scan',
    },
  });
});

// Mount routes with authentication and rate limiting
app.use(
  '/api/scanner',
  authenticateScanner,
  verifyRateLimit,
  verifyRoutes
);

app.use(
  '/api/scanner',
  authenticateScanner,
  historyRateLimit,
  ticketRoutes
);

app.use(
  '/api/scanner',
  authenticateScanner,
  historyRateLimit,
  historyRoutes
);

app.use(
  '/api/scanner',
  authenticateScanner,
  historyRateLimit,
  statsRoutes
);

// Admin routes with admin authentication
app.use(
  '/api/scanner',
  authenticateAdmin,
  adminRateLimit,
  adminRoutes
);

// 404 handler
app.use(notFoundHandler);

// Global error handler
app.use(errorHandler);

// Start server
app.listen(PORT, () => {
  logger.info('TPC Ops Scanner API started', {
    port: PORT,
    environment: process.env.NODE_ENV || 'development',
    nodeVersion: process.version,
  });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  logger.info('SIGINT received, shutting down gracefully');
  process.exit(0);
});

export default app;
