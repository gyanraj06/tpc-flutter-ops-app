/**
 * Type definitions for scanner API
 */

export enum ScanResult {
  VALID_UNUSED = 'valid_unused',
  ALREADY_USED = 'already_used',
  INVALID = 'invalid',
  NOT_FOUND = 'not_found',
  SIGNATURE_MISMATCH = 'signature_mismatch',
  EXPIRED = 'expired',
}

export interface VerifyScanRequest {
  qrData: string;
  signature: string;
  scannerId: string;
  scannerName?: string;
  location?: string;
  markAsUsed: boolean;
}

export interface TicketInfo {
  ticketNumber: string;
  customerName: string;
  email?: string;
  phoneNumber?: string;
  eventDate?: string;
  ticketPrice?: number;
  usedAt?: string;
  reason?: string;
}

export interface BatchInfo {
  eventTitle: string;
  venue: string;
}

export interface VerifyScanResponse {
  success: boolean;
  result: ScanResult;
  message: string;
  allowEntry: boolean;
  ticket?: TicketInfo;
  batch?: BatchInfo;
  scanTime: string;
}

export interface ManualEntryRequest {
  ticketNumber: string;
  scannerId: string;
  scannerName?: string;
  reason: string;
}

export interface UndoScanRequest {
  ticketNumber: string;
  adminId: string;
  reason: string;
}

export interface ScanHistoryQuery {
  scannerId?: string;
  batchId?: string;
  limit?: number;
  offset?: number;
  from?: string;
  to?: string;
}

export interface ScanHistoryItem {
  id: string;
  ticketNumber: string;
  customerName: string;
  scanResult: string;
  scannedBy: string | null;
  scannedAt: string;
  scanNotes: string | null;
}

export interface BatchStats {
  totalTickets: number;
  ticketsUsed: number;
  ticketsRemaining: number;
  ticketsInvalid: number;
  usagePercentage: number;
  lastScanTime: string | null;
}

export interface ApiError {
  success: false;
  error: string;
  message: string;
  details?: string;
  timestamp: string;
}
