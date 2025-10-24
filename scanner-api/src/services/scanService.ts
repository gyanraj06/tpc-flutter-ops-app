import { getSupabaseClient } from '../utils/supabase';
import { logger } from '../utils/logger';
import { ScanHistoryQuery, ScanHistoryItem, BatchStats } from '../types/scanner.types';

/**
 * Service for scan history and statistics
 */

export class ScanService {
  private supabase = getSupabaseClient();

  /**
   * Get scan history with filtering
   */
  async getScanHistory(query: ScanHistoryQuery): Promise<{ scans: ScanHistoryItem[]; total: number }> {
    try {
      logger.debug('Fetching scan history', query);

      let queryBuilder = this.supabase
        .from('bulk_ticket_scans')
        .select(`
          id,
          scan_result,
          scanned_by,
          scanned_at,
          scan_notes,
          ticket:bulk_tickets(ticket_number, customer_name)
        `, { count: 'exact' })
        .order('scanned_at', { ascending: false });

      // Apply filters
      if (query.scannerId) {
        queryBuilder = queryBuilder.eq('scanned_by', query.scannerId);
      }

      if (query.batchId) {
        queryBuilder = queryBuilder.eq('batch_id', query.batchId);
      }

      if (query.from) {
        queryBuilder = queryBuilder.gte('scanned_at', query.from);
      }

      if (query.to) {
        queryBuilder = queryBuilder.lte('scanned_at', query.to);
      }

      // Apply pagination
      const limit = query.limit || 50;
      const offset = query.offset || 0;
      queryBuilder = queryBuilder.range(offset, offset + limit - 1);

      const { data, error, count } = await queryBuilder;

      if (error) {
        throw error;
      }

      const scans: ScanHistoryItem[] = (data || []).map((scan: any) => ({
        id: scan.id,
        ticketNumber: scan.ticket?.ticket_number || 'Unknown',
        customerName: scan.ticket?.customer_name || 'Unknown',
        scanResult: scan.scan_result,
        scannedBy: scan.scanned_by,
        scannedAt: scan.scanned_at,
        scanNotes: scan.scan_notes,
      }));

      logger.info('Scan history fetched', { count: scans.length, total: count });

      return {
        scans,
        total: count || 0,
      };
    } catch (error) {
      logger.error('Error fetching scan history', { error: error instanceof Error ? error.message : 'Unknown error' });
      throw error;
    }
  }

  /**
   * Get batch statistics
   */
  async getBatchStats(batchId: string): Promise<BatchStats | null> {
    try {
      logger.debug('Fetching batch statistics', { batchId });

      // Get batch info
      const { data: batch, error: batchError } = await this.supabase
        .from('bulk_ticket_batches')
        .select('*')
        .eq('id', batchId)
        .single();

      if (batchError || !batch) {
        logger.warn('Batch not found', { batchId });
        return null;
      }

      // Get ticket statistics
      const { data: tickets, error: ticketsError } = await this.supabase
        .from('bulk_tickets')
        .select('is_used, is_valid, used_at')
        .eq('batch_id', batchId);

      if (ticketsError) {
        throw ticketsError;
      }

      const totalTickets = tickets?.length || 0;
      const ticketsUsed = tickets?.filter((t) => t.is_used).length || 0;
      const ticketsInvalid = tickets?.filter((t) => !t.is_valid).length || 0;
      const ticketsRemaining = totalTickets - ticketsUsed - ticketsInvalid;
      const usagePercentage = totalTickets > 0 ? Math.round((ticketsUsed / totalTickets) * 100) : 0;

      // Get last scan time
      const { data: lastScan } = await this.supabase
        .from('bulk_ticket_scans')
        .select('scanned_at')
        .eq('batch_id', batchId)
        .order('scanned_at', { ascending: false })
        .limit(1)
        .single();

      const stats: BatchStats = {
        totalTickets,
        ticketsUsed,
        ticketsRemaining,
        ticketsInvalid,
        usagePercentage,
        lastScanTime: lastScan?.scanned_at || null,
      };

      logger.info('Batch statistics fetched', { batchId, stats });

      return stats;
    } catch (error) {
      logger.error('Error fetching batch statistics', { batchId, error: error instanceof Error ? error.message : 'Unknown error' });
      throw error;
    }
  }

  /**
   * Log scan attempt (for cases not handled by verify_and_use_ticket function)
   */
  async logScan(ticketId: string, batchId: string, scanResult: string, scannedBy: string, notes?: string): Promise<void> {
    try {
      await this.supabase.from('bulk_ticket_scans').insert({
        ticket_id: ticketId,
        batch_id: batchId,
        scan_result: scanResult,
        scanned_by: scannedBy,
        scan_notes: notes,
      });

      logger.debug('Scan logged', { ticketId, scanResult });
    } catch (error) {
      logger.error('Error logging scan', { ticketId, error: error instanceof Error ? error.message : 'Unknown error' });
      // Don't throw - logging shouldn't block the scan operation
    }
  }
}
