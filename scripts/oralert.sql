SET linesize 200 pagesize 200
col RECORD_ID FOR 9999999 head ID
col MESSAGE_TEXT FOR a120 head Message

SELECT record_id, message_text
FROM X$DBGALERTEXT
WHERE originating_timestamp > systimestamp - 1 AND regexp_like(message_text, '(ORA-|error)');
