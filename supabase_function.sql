-- Run this in Supabase SQL Editor
CREATE OR REPLACE FUNCTION verify_and_use_ticket(
  p_qr_data TEXT,
  p_signature TEXT,
  p_scanner_id VARCHAR DEFAULT 'default-scanner',
  p_scan_notes TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  v_ticket bulk_tickets%ROWTYPE;
  v_batch bulk_ticket_batches%ROWTYPE;
  v_expected_signature TEXT;
  v_secret_key TEXT := '14dc0142f09d636f82a8004dd76f9049c1feb59132cb02b78328be791240de79';
  v_parsed_data JSON;
  v_ticket_number VARCHAR;
BEGIN
  -- Verify HMAC signature
  v_expected_signature := encode(hmac(p_qr_data, v_secret_key, 'sha256'), 'hex');

  IF v_expected_signature != p_signature THEN
    RETURN json_build_object(
      'status', 'signature_mismatch',
      'message', 'Invalid QR code - possible forgery',
      'isValid', false,
      'ticketCode', NULL,
      'attendeeName', NULL,
      'ticketType', NULL,
      'eventName', NULL,
      'errorReason', 'QR code signature mismatch'
    );
  END IF;

  -- Parse QR data to get ticket number
  BEGIN
    v_parsed_data := p_qr_data::json;
    v_ticket_number := v_parsed_data->>'ticketNumber';
  EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
      'status', 'invalid',
      'message', 'Invalid QR code format',
      'isValid', false,
      'errorReason', 'Could not parse QR data'
    );
  END;

  -- Lock and fetch ticket
  SELECT * INTO v_ticket
  FROM bulk_tickets
  WHERE ticket_number = v_ticket_number
  FOR UPDATE;

  -- Check if ticket exists
  IF NOT FOUND THEN
    -- Log scan attempt (skip if table structure is different)
    -- INSERT INTO bulk_ticket_scans (ticket_id, batch_id, scan_result, scanned_by, scan_notes)
    -- VALUES (NULL, NULL, 'not_found', p_scanner_id, p_scan_notes);

    RETURN json_build_object(
      'status', 'invalid',
      'message', 'Ticket not found',
      'isValid', false,
      'ticketCode', v_ticket_number,
      'errorReason', 'Ticket does not exist in database'
    );
  END IF;

  -- Fetch batch info
  SELECT * INTO v_batch
  FROM bulk_ticket_batches
  WHERE id = v_ticket.batch_id;

  -- Check if ticket is valid
  IF NOT v_ticket.is_valid THEN
    -- Log scan attempt
    -- INSERT INTO bulk_ticket_scans (ticket_id, batch_id, scan_result, scanned_by, scan_notes)
    -- VALUES (v_ticket.id, v_ticket.batch_id, 'invalid', p_scanner_id, p_scan_notes);

    RETURN json_build_object(
      'status', 'invalid',
      'message', 'Ticket has been invalidated',
      'isValid', false,
      'ticketCode', v_ticket.ticket_number,
      'attendeeName', v_ticket.customer_name,
      'ticketType', 'Bulk Ticket',
      'eventName', v_batch.event_title,
      'errorReason', 'Ticket was cancelled by vendor'
    );
  END IF;

  -- Check if already used
  IF v_ticket.is_used THEN
    -- Log scan attempt
    -- INSERT INTO bulk_ticket_scans (ticket_id, batch_id, scan_result, scanned_by, scan_notes)
    -- VALUES (v_ticket.id, v_ticket.batch_id, 'already_used', p_scanner_id, p_scan_notes);

    RETURN json_build_object(
      'status', 'already_scanned',
      'message', 'Ticket already used',
      'isValid', false,
      'ticketCode', v_ticket.ticket_number,
      'attendeeName', v_ticket.customer_name,
      'ticketType', 'Bulk Ticket',
      'eventName', v_batch.event_title,
      'previousScanTime', v_ticket.used_at,
      'scannedBy', p_scanner_id,
      'errorReason', 'This ticket was already scanned at ' || to_char(v_ticket.used_at, 'HH24:MI:SS')
    );
  END IF;

  -- Mark as used
  UPDATE bulk_tickets
  SET is_used = TRUE, used_at = NOW()
  WHERE id = v_ticket.id;

  -- Log successful scan (skip if table structure is different)
  -- INSERT INTO bulk_ticket_scans (ticket_id, batch_id, scan_result, scanned_by, scan_notes)
  -- VALUES (v_ticket.id, v_ticket.batch_id, 'success', p_scanner_id, p_scan_notes);

  -- Return success
  RETURN json_build_object(
    'status', 'valid',
    'message', 'Ticket verified - ALLOW ENTRY',
    'isValid', true,
    'ticketCode', v_ticket.ticket_number,
    'attendeeName', v_ticket.customer_name,
    'ticketType', 'Bulk Ticket - ₹' || v_ticket.ticket_price::text,
    'eventName', v_batch.event_title,
    'venue', v_batch.venue,
    'eventDate', v_ticket.event_date::text
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
