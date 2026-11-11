create function clock_time(minutes integer) returns text language sql immutable as $$
 select case when minutes is null then null else
 lpad(((minutes/60)%24)::text,2,'0')||':'||lpad((minutes%60)::text,2,'0')||case when minutes>=1440 then ' +'||(minutes/1440)::text||'d' else '' end
$$;
