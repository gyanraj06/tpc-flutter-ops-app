import { createClient, SupabaseClient } from '@supabase/supabase-js';

let supabaseClient: SupabaseClient | null = null;

/**
 * Get or create Supabase client singleton
 */
export const getSupabaseClient = (): SupabaseClient => {
  if (supabaseClient) {
    return supabaseClient;
  }

  const supabaseUrl = process.env.VITE_SUPABASE_URL;
  const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!supabaseUrl || !supabaseKey) {
    throw new Error(
      'Missing Supabase configuration. Please set VITE_SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment variables.'
    );
  }

  supabaseClient = createClient(supabaseUrl, supabaseKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  return supabaseClient;
};

/**
 * Database types for bulk tickets system
 */
export interface BulkTicket {
  id: string;
  batch_id: string;
  ticket_number: string;
  qr_code_data: string;
  qr_code_signature: string;
  customer_name: string;
  email: string;
  phone_number: string;
  event_date: string;
  ticket_price: number;
  pdf_generated: boolean;
  pdf_url: string | null;
  is_valid: boolean;
  is_used: boolean;
  used_at: string | null;
  email_sent: boolean;
  whatsapp_sent: boolean;
  created_at: string;
}

export interface BulkTicketBatch {
  id: string;
  vendor_id: string;
  event_title: string;
  venue: string;
  primary_color: string;
  secondary_color: string;
  accent_color: string;
  ticket_prefix: string;
  starting_number: number;
  total_tickets: number;
  status: string;
  zip_file_url: string | null;
  created_at: string;
  updated_at: string;
}

export interface BulkTicketScan {
  id: string;
  ticket_id: string;
  batch_id: string | null;
  scan_result: string;
  scanned_by: string | null;
  scan_notes: string | null;
  scanned_at: string;
}

export type TicketWithBatch = BulkTicket & {
  batch: BulkTicketBatch;
};
