import { getSupabaseClient, BulkTicket, TicketWithBatch } from '../utils/supabase';
import { logger } from '../utils/logger';
import { ScanResult } from '../types/scanner.types';

/**
 * Service for ticket database operations
 */

export interface TicketVerificationResult {
  result: ScanResult;
  message: string;
  allowEntry: boolean;
  ticket?: TicketWithBatch;
}

export class TicketService {
  private supabase = getSupabaseClient();

  /**
   * Fetch ticket with batch details by ticket number
   */
  async getTicketByNumber(ticketNumber: string): Promise<TicketWithBatch | null> {
    try {
      logger.debug('Fetching ticket from database', { ticketNumber });

      const { data, error } = await this.supabase
        .from('bulk_tickets')
        .select(`
          *,
          batch:bulk_ticket_batches(*)
        `)
        .eq('ticket_number', ticketNumber)
        .single();

      if (error) {
        if (error.code === 'PGRST116') {
          // No rows returned
          logger.warn('Ticket not found in database', { ticketNumber });
          return null;
        }
        throw error;
      }

      logger.debug('Ticket fetched successfully', { ticketId: data.id });
      return data as TicketWithBatch;
    } catch (error) {
      logger.error('Error fetching ticket', { ticketNumber, error: error instanceof Error ? error.message : 'Unknown error' });
      throw error;
    }
  }

  /**
   * Verify ticket status (valid, used, etc.)
   */
  async verifyTicketStatus(ticketNumber: string): Promise<TicketVerificationResult> {
    try {
      // Fetch ticket
      const ticket = await this.getTicketByNumber(ticketNumber);

      if (!ticket) {
        return {
          result: ScanResult.NOT_FOUND,
          message: 'Ticket not found in database',
          allowEntry: false,
        };
      }

      // Check if ticket is valid
      if (!ticket.is_valid) {
        logger.warn('Ticket is invalid', { ticketNumber, reason: 'Invalidated by vendor' });
        return {
          result: ScanResult.INVALID,
          message: 'Ticket has been invalidated',
          allowEntry: false,
          ticket,
        };
      }

      // Check if already used
      if (ticket.is_used) {
        logger.warn('Ticket already used', { ticketNumber, usedAt: ticket.used_at });
        return {
          result: ScanResult.ALREADY_USED,
          message: 'Ticket has already been used',
          allowEntry: false,
          ticket,
        };
      }

      // Ticket is valid and unused
      logger.info('Ticket is valid and unused', { ticketNumber });
      return {
        result: ScanResult.VALID_UNUSED,
        message: 'Ticket verified successfully - ALLOW ENTRY',
        allowEntry: true,
        ticket,
      };
    } catch (error) {
      logger.error('Error verifying ticket status', { ticketNumber, error: error instanceof Error ? error.message : 'Unknown error' });
      throw error;
    }
  }

  /**
   * Mark ticket as used (using PostgreSQL function for concurrent safety)
   */
  async markTicketAsUsed(ticketNumber: string, scannerId: string, scannerName?: string, location?: string): Promise<TicketVerificationResult> {
    try {
      logger.info('Marking ticket as used', { ticketNumber, scannerId });

      // Call PostgreSQL function that handles concurrent scans with row locking
      const { data, error } = await this.supabase.rpc('verify_and_use_ticket', {
        p_ticket_number: ticketNumber,
        p_scanner_id: scannerName || scannerId,
        p_scan_notes: location ? `Scanned at ${location}` : null,
      });

      if (error) {
        logger.error('Error calling verify_and_use_ticket function', { error: error.message });
        throw error;
      }

      logger.info('Ticket verification result', { ticketNumber, result: data.result });

      // Parse result
      const result = data.result as ScanResult;
      const message = data.message as string;
      const allowEntry = result === ScanResult.VALID_UNUSED;

      // Fetch full ticket details if needed
      let ticket: TicketWithBatch | undefined;
      if (data.ticket_id) {
        const { data: ticketData } = await this.supabase
          .from('bulk_tickets')
          .select(`
            *,
            batch:bulk_ticket_batches(*)
          `)
          .eq('id', data.ticket_id)
          .single();

        if (ticketData) {
          ticket = ticketData as TicketWithBatch;
        }
      }

      return {
        result,
        message,
        allowEntry,
        ticket,
      };
    } catch (error) {
      logger.error('Error marking ticket as used', { ticketNumber, error: error instanceof Error ? error.message : 'Unknown error' });
      throw error;
    }
  }

  /**
   * Get ticket details with scan history
   */
  async getTicketDetails(ticketNumber: string) {
    try {
      const ticket = await this.getTicketByNumber(ticketNumber);

      if (!ticket) {
        return null;
      }

      // Fetch scan history
      const { data: scans } = await this.supabase
        .from('bulk_ticket_scans')
        .select('*')
        .eq('ticket_id', ticket.id)
        .order('scanned_at', { ascending: false })
        .limit(10);

      return {
        ticket,
        scanHistory: scans || [],
      };
    } catch (error) {
      logger.error('Error fetching ticket details', { ticketNumber, error: error instanceof Error ? error.message : 'Unknown error' });
      throw error;
    }
  }

  /**
   * Manually mark ticket as used (for damaged QR codes)
   */
  async manualEntry(ticketNumber: string, scannerId: string, reason: string, scannerName?: string): Promise<TicketVerificationResult> {
    try {
      logger.info('Manual entry for ticket', { ticketNumber, scannerId, reason });

      // Verify ticket exists and is valid
      const verification = await this.verifyTicketStatus(ticketNumber);

      if (!verification.allowEntry) {
        return verification;
      }

      // Mark as used
      const ticket = verification.ticket!;

      const { error: updateError } = await this.supabase
        .from('bulk_tickets')
        .update({
          is_used: true,
          used_at: new Date().toISOString(),
        })
        .eq('id', ticket.id);

      if (updateError) {
        throw updateError;
      }

      // Log manual entry
      await this.supabase.from('bulk_ticket_scans').insert({
        ticket_id: ticket.id,
        batch_id: ticket.batch_id,
        scan_result: 'manual_entry',
        scanned_by: scannerName || scannerId,
        scan_notes: `Manual entry: ${reason}`,
      });

      logger.info('Manual entry successful', { ticketNumber });

      return {
        result: ScanResult.VALID_UNUSED,
        message: 'Ticket marked as used manually',
        allowEntry: true,
        ticket,
      };
    } catch (error) {
      logger.error('Error during manual entry', { ticketNumber, error: error instanceof Error ? error.message : 'Unknown error' });
      throw error;
    }
  }

  /**
   * Undo a ticket scan (admin only)
   */
  async undoScan(ticketNumber: string, adminId: string, reason: string): Promise<TicketVerificationResult> {
    try {
      logger.info('Undoing scan for ticket', { ticketNumber, adminId, reason });

      const ticket = await this.getTicketByNumber(ticketNumber);

      if (!ticket) {
        return {
          result: ScanResult.NOT_FOUND,
          message: 'Ticket not found',
          allowEntry: false,
        };
      }

      if (!ticket.is_used) {
        return {
          result: ScanResult.INVALID,
          message: 'Ticket has not been used yet',
          allowEntry: false,
          ticket,
        };
      }

      // Mark as unused
      const { error: updateError } = await this.supabase
        .from('bulk_tickets')
        .update({
          is_used: false,
          used_at: null,
        })
        .eq('id', ticket.id);

      if (updateError) {
        throw updateError;
      }

      // Log undo action
      await this.supabase.from('bulk_ticket_scans').insert({
        ticket_id: ticket.id,
        batch_id: ticket.batch_id,
        scan_result: 'undo_scan',
        scanned_by: adminId,
        scan_notes: `Undo scan: ${reason}`,
      });

      logger.info('Scan undone successfully', { ticketNumber });

      return {
        result: ScanResult.VALID_UNUSED,
        message: 'Ticket scan undone successfully',
        allowEntry: false,
        ticket,
      };
    } catch (error) {
      logger.error('Error undoing scan', { ticketNumber, error: error instanceof Error ? error.message : 'Unknown error' });
      throw error;
    }
  }
}
