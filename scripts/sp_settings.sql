column sqlprompt_col new_value sqlprompt_value
set termout off
define sqlprompt_value='NOT_CONNECTED'
select
   case when upper(substr(host_name,1,3)) = 'FR1' then 'fr1-Ruby'
        when upper(substr(host_name,1,3)) = 'FR2' then 'fr2-Sapphire'
        when upper(substr(host_name,1,3)) = 'US1' then 'us1-Emerald'
        when upper(substr(host_name,1,3)) = 'US2' then 'us2-Diamond'
        else 'XXX' end
   || upper(substr(host_name,4,4))
   || '/' || instance_name as sqlprompt_col
from v$instance;
set pagesize 1000
set linesize 170
set feedback on
alter session set nls_date_format='DD-MM-YYYY HH24:MI:SS';
alter session set nls_timestamp_format='DD-MM-YYYY HH24:MI:SS.FF';
alter session set nls_timestamp_tz_format='DD-MM-YYYY HH24:MI:SS.FF TZH:TZM';
set termout on
set sqlprompt '&sqlprompt_value> '
select username,account_status from dba_users order by 1;
