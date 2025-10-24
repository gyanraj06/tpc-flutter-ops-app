-- PostgreSQL function for concurrent-safe ticket verification and usage
-- This function uses row-level locking to prevent duplicate scans

CREATE OR REPLACE FUNCTION verify_and_use_ticket(
  p_ticket_number VARCHAR,
  p_scanner_id VARCHAR,
  p_scan_notes TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  v_ticket bulk_tickets;
  v_result JSON;
  v_scan_id UUID;
BEGIN
  -- Lock the ticket row for update (prevents concurrent access)
  SELECT * INTO v_ticket
  FROM bulk_tickets
  WHERE ticket_number = p_ticket_number
  FOR UPDATE;

  -- Check if ticket exists
  IF NOT FOUND THEN
    -- Log failed scan attempt
    INSERT INTO bulk_ticket_scans (ticket_id, batch_id, scan_result, scanned_by, scan_notes)
    VALUES (NULL, NULL, 'not_found', p_scanner_id, p_scan_notes);

    RETURN json_build_object(
      'result', 'not_found',
      'message', 'Ticket not found in database',
      'ticket_id', NULL
    );
  END IF;

  -- Check if ticket is valid
  IF NOT v_ticket.is_valid THEN
    -- Log failed scan
    INSERT INTO bulk_ticket_scans (ticket_id, batch_id, scan_result, scanned_by, scan_notes)
    VALUES (v_ticket.id, v_ticket.batch_id, 'invalid', p_scanner_id, p_scan_notes);

    RETURN json_build_object(
      'result', 'invalid',
      'message', 'Ticket has been invalidated',
      'ticket_id', v_ticket.id
    );
  END IF;

  -- Check if already used
  IF v_ticket.is_used THEN
    -- Log duplicate scan attempt
    INSERT INTO bulk_ticket_scans (ticket_id, batch_id, scan_result, scanned_by, scan_notes)
    VALUES (v_ticket.id, v_ticket.batch_id, 'already_used', p_scanner_id,
            COALESCE(p_scan_notes || ' | ', '') || 'Previous use: ' || v_ticket.used_at::TEXT);

    RETURN json_build_object(
      'result', 'already_used',
      'message', 'Ticket has already been used',
      'ticket_id', v_ticket.id,
      'used_at', v_ticket.used_at
    );
  END IF;

  -- Ticket is valid and unused - mark as used
  UPDATE bulk_tickets
  SET
    is_used = TRUE,
    used_at = NOW()
  WHERE id = v_ticket.id;

  -- Log successful scan
  INSERT INTO bulk_ticket_scans (ticket_id, batch_id, scan_result, scanned_by, scan_notes)
  VALUES (v_ticket.id, v_ticket.batch_id, 'success', p_scanner_id, p_scan_notes)
  RETURNING id INTO v_scan_id;

  -- Return success
  RETURN json_build_object(
    'result', 'valid_unused',
    'message', 'Ticket verified successfully - ALLOW ENTRY',
    'ticket_id', v_ticket.id,
    'scan_id', v_scan_id,
    'used_at', NOW()
  );

EXCEPTION
  WHEN OTHERS THEN
    -- Log error
    RAISE WARNING 'Error in verify_and_use_ticket: %', SQLERRM;

    RETURN json_build_object(
      'result', 'error',
      'message', 'Database error occurred',
      'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
-- GRANT EXECUTE ON FUNCTION verify_and_use_ticket(VARCHAR, VARCHAR, TEXT) TO authenticated;
-- GRANT EXECUTE ON FUNCTION verify_and_use_ticket(VARCHAR, VARCHAR, TEXT) TO service_role;

-- Add comment
COMMENT ON FUNCTION verify_and_use_ticket IS
'Atomically verify and mark a ticket as used with row-level locking to prevent duplicate scans';
