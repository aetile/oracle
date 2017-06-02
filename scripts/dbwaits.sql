set lines 200 pages 9999
select * 
from (select  ev.event, sum(ev.total_waits) total_waits, sum(ev.total_timeouts) total_timeouts, round(sum(ev.time_waited_micro)/1000000) time_waited_seconds
      from stats$system_event ev, stats$snapshot sn
      where ev.snap_id = sn.snap_id
      --and TO_CHAR (sn.snap_time, 'DD.MM.YYYY') = TO_CHAR (SYSDATE, 'DD.MM.YYYY')
      and sn.snap_time >= SYSDATE-7
      and ev.event not like 'SQL*Net%'
      and LOWER(ev.event) not like '%idle%'
      and LOWER(ev.event) not like '%timer%'
      and LOWER(ev.event) not like '%slave%'
      and LOWER(ev.event) not like '%remote message%'
      and LOWER(ev.event) not like '%unread message%'
      and LOWER(ev.event) not like '%sleep%'
      and LOWER(ev.event) not like '%streams aq%'
      and event not in ('pmon timer','rdbms ipc message','dispatcher timer','smon timer','PING')
      --and LOWER(event) like '%wait%'
      group by ev.event
      order by 4 desc)
where rownum < 11;


