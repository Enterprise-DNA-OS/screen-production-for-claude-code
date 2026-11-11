create table settings (key text primary key, value integer not null check(value>0));
insert into settings values ('rest_minutes',720),('long_day_minutes',720);
create table productions (
 id uuid primary key default gen_random_uuid(), ref text unique not null, name text not null,
 status text not null default 'prep' check(status in ('prep','shooting','post','archived')),
 timezone text not null default 'Pacific/Auckland',
 created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table locations (
 id uuid primary key default gen_random_uuid(), ref text unique not null, name text not null,
 address text not null default '', permission_until date, emergency_plan text not null default '',
 created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table people (
 id uuid primary key default gen_random_uuid(), ref text unique not null, name text not null,
 kind text not null default 'crew' check(kind in ('crew','cast')), department text not null default '',
 created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table shoot_days (
 id uuid primary key default gen_random_uuid(), ref text unique not null, production_id uuid not null references productions,
 location_id uuid not null references locations, shoot_date date not null, unit text not null default 'Main',
 start_min integer not null default 420 check(start_min between 0 and 1439),
 end_min integer not null default 1080 check(end_min between 1 and 2880),
 safety_contact text not null default '', assessment_ref text not null default '', briefing text not null default '',
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 check(end_min>start_min and end_min-start_min<=1440), unique(production_id,shoot_date,unit));
create table scenes (
 id uuid primary key default gen_random_uuid(), ref text unique not null, production_id uuid not null references productions,
 name text not null, location_id uuid not null references locations, day_id uuid references shoot_days,
 eighths integer not null default 8 check(eighths>0), duration_min integer not null default 30 check(duration_min>0),
 order_no integer not null default 1 check(order_no>0), status text not null default 'planned' check(status in ('planned','shot','cut')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table scene_cast (
 id uuid primary key default gen_random_uuid(), ref text unique not null, scene_id uuid not null references scenes,
 person_id uuid not null references people, character_name text not null,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(scene_id,person_id));
create table bookings (
 id uuid primary key default gen_random_uuid(), ref text unique not null, day_id uuid not null references shoot_days,
 person_id uuid not null references people, role text not null default '',
 start_min integer not null check(start_min between 0 and 1439), end_min integer not null check(end_min between 1 and 2880),
 status text not null default 'tentative' check(status in ('tentative','confirmed','absent')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 check(end_min>start_min and end_min-start_min<=1440), unique(day_id,person_id));
create table risks (
 id uuid primary key default gen_random_uuid(), ref text unique not null, day_id uuid not null references shoot_days,
 description text not null, controls text not null default '', owner text not null default '', review_due date not null,
 status text not null default 'open' check(status in ('open','controlled','closed')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 check(status<>'controlled' or (length(trim(controls))>0 and length(trim(owner))>0)));
create table work_logs (
 id uuid primary key default gen_random_uuid(), ref text unique not null, production_id uuid not null references productions,
 person_id uuid not null references people, work_date date not null,
 status text not null default 'present' check(status in ('present','sick','absent')),
 start_min integer, end_min integer, break_min integer not null default 0 check(break_min>=0),
 source text not null default 'manual', source_row jsonb,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(production_id,person_id,work_date),
 check((status='present' and start_min is not null and start_min between 0 and 1439 and
 (end_min is null or (end_min>start_min and end_min<=2880 and end_min-start_min<=1440 and break_min<=end_min-start_min)))
 or (status in ('sick','absent') and start_min is null and end_min is null and break_min=0)));
create table notes (
 id uuid primary key default gen_random_uuid(), ref text unique not null, production_id uuid not null references productions, body text not null,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table audit_events (
 id uuid primary key default gen_random_uuid(), entity text not null, record_id uuid not null,
 action text not null, before_row jsonb, after_row jsonb, actor text not null default current_user,
 created_at timestamptz not null default now());
create function stamp_update() returns trigger language plpgsql as $$ begin new.updated_at=clock_timestamp(); return new; end $$;
create function audit_change() returns trigger language plpgsql as $$ begin
 insert into audit_events(entity,record_id,action,before_row,after_row) values(TG_TABLE_NAME,new.id,TG_OP,case when TG_OP='UPDATE' then to_jsonb(old) else null end,to_jsonb(new));return new;end $$;
create function validate_scene() returns trigger language plpgsql as $$ declare d shoot_days;begin
 if new.day_id is not null then select * into d from shoot_days where id=new.day_id;
 if d.production_id<>new.production_id or d.location_id<>new.location_id then raise exception 'Scene and shoot day must share production and location';end if;
 end if;
 if new.status='shot' and (new.day_id is null or d.shoot_date>current_date) then raise exception 'A shot scene requires a shoot day on or before today';end if;
 return new;end $$;
create trigger scene_consistency before insert or update on scenes for each row execute function validate_scene();
create function validate_day() returns trigger language plpgsql as $$ begin
 if exists(select 1 from scenes s where s.day_id=new.id and (s.production_id<>new.production_id or s.location_id<>new.location_id or (s.status='shot' and new.shoot_date>current_date))) then raise exception 'Day change conflicts with assigned scenes';end if;return new;end $$;
create trigger day_consistency before update on shoot_days for each row execute function validate_day();
create function validate_cast() returns trigger language plpgsql as $$ begin
 if not exists(select 1 from people where id=new.person_id and kind='cast') then raise exception 'Scene cast requires a cast member';end if;return new;end $$;
create trigger cast_consistency before insert or update on scene_cast for each row execute function validate_cast();
create function validate_person() returns trigger language plpgsql as $$ begin
 if new.kind<>'cast' and exists(select 1 from scene_cast where person_id=new.id) then raise exception 'Person has cast assignments';end if;return new;end $$;
create trigger person_consistency before update on people for each row execute function validate_person();
do $$ declare t text;begin
 foreach t in array array['productions','locations','people','shoot_days','scenes','scene_cast','bookings','risks','work_logs','notes'] loop
 execute format('create trigger updated before update on %I for each row execute function stamp_update()',t);
 execute format('create trigger audit after insert or update on %I for each row execute function audit_change()',t);
 execute format('alter table %I enable row level security',t); execute format('revoke all on %I from public',t);
 end loop;end $$;
alter table settings enable row level security; alter table audit_events enable row level security;
revoke all on settings,audit_events from public;
create view v_scene_plan as
 select s.id,s.ref,p.ref production,s.name,l.name location,d.ref shoot_day,d.shoot_date,s.order_no,s.eighths,s.duration_min,s.status
 from scenes s join productions p on p.id=s.production_id join locations l on l.id=s.location_id left join shoot_days d on d.id=s.day_id;
create view v_schedule as
 select d.id,d.ref,p.ref production,p.name title,d.shoot_date,d.unit,l.name location,d.start_min,d.end_min,
 (select count(*) from scenes s where s.day_id=d.id and s.status<>'cut') scenes,
 coalesce((select sum(duration_min) from scenes s where s.day_id=d.id and s.status='planned'),0) planned_minutes,
 (select count(*) from bookings b where b.day_id=d.id and b.status='confirmed') confirmed_people,
 d.safety_contact,d.assessment_ref,d.briefing
 from shoot_days d join productions p on p.id=d.production_id join locations l on l.id=d.location_id where p.status<>'archived';
create view v_cast_gaps as
 select d.id day_id,d.ref shoot_day,p.ref production,d.shoot_date,s.ref scene,c.name person,c.ref person_ref,sc.character_name,
 coalesce(b.status,'not booked') booking_status
 from scenes s join scene_cast sc on sc.scene_id=s.id join people c on c.id=sc.person_id
 join shoot_days d on d.id=s.day_id join productions p on p.id=s.production_id
 left join bookings b on b.day_id=d.id and b.person_id=c.id
 where s.status='planned' and (b.id is null or b.status<>'confirmed' or b.start_min>d.start_min or b.end_min<d.end_min);
create view v_conflicts as
 select p.name person,p.ref person_ref,da.ref first_day,db.ref second_day,da.shoot_date,
 a.id booking_id,b.id other_booking_id
 from bookings a join bookings b on a.person_id=b.person_id and a.id::text<b.id::text
 join shoot_days da on da.id=a.day_id join shoot_days db on db.id=b.day_id join people p on p.id=a.person_id
 where a.status<>'absent' and b.status<>'absent'
 and da.shoot_date+a.start_min*interval '1 minute'<db.shoot_date+b.end_min*interval '1 minute'
 and db.shoot_date+b.start_min*interval '1 minute'<da.shoot_date+a.end_min*interval '1 minute';
create view v_location_conflicts as
 select a.ref first_day,b.ref second_day,l.name location,a.shoot_date
 from shoot_days a join shoot_days b on a.location_id=b.location_id and a.id::text<b.id::text join locations l on l.id=a.location_id
 join productions pa on pa.id=a.production_id join productions pb on pb.id=b.production_id
 where pa.status<>'archived' and pb.status<>'archived'
 and a.shoot_date+a.start_min*interval '1 minute'<b.shoot_date+b.end_min*interval '1 minute'
 and b.shoot_date+b.start_min*interval '1 minute'<a.shoot_date+a.end_min*interval '1 minute';
create view v_compliance as
 select d.id day_id,d.ref shoot_day,d.shoot_date,'CALL-SHEET' rule,'Missing safety contact, assessment or daily briefing' issue,'https://www.screensafe.co.nz/template-categories/h-s-workplace-forms' source
 from shoot_days d where trim(safety_contact)='' or trim(assessment_ref)='' or trim(briefing)=''
 union all
 select d.id,d.ref,d.shoot_date,'LOCATION','Permission or emergency plan missing or out of date','https://www.screensafe.co.nz/guideline-categories/all-guidelines'
 from shoot_days d join locations l on l.id=d.location_id where l.permission_until is null or l.permission_until<d.shoot_date or trim(l.emergency_plan)=''
 union all
 select d.id,d.ref,d.shoot_date,'RISK-REVIEW',r.ref||': '||r.description,'https://www.worksafe.govt.nz/managing-health-and-safety/managing-risks/how-to-manage-work-risks/'
 from risks r join shoot_days d on d.id=r.day_id where r.status<>'closed' and (r.status='open' or r.review_due<d.shoot_date or r.review_due<current_date);
create view v_hours as
 select w.id,w.ref,p.ref production,c.ref person_ref,c.name person,w.work_date,w.status,w.start_min,w.end_min,w.break_min,
 w.end_min-w.start_min-w.break_min worked_minutes,
 case when w.status<>'present' then w.status when w.end_min is null then 'missing wrap'
 when w.end_min-w.start_min-w.break_min>(select value from settings where key='long_day_minutes') then 'long day policy' else 'recorded' end flag
 from work_logs w join productions p on p.id=w.production_id join people c on c.id=w.person_id;
create view v_rest_gaps as
 select person,person_ref,ref,work_date,round(extract(epoch from (starts_at-previous_end))/60) rest_minutes
 from (select c.name person,c.ref person_ref,w.ref,w.work_date,w.work_date+w.start_min*interval '1 minute' starts_at,
 lag(w.work_date+w.end_min*interval '1 minute') over(partition by w.person_id order by w.work_date+w.start_min*interval '1 minute',w.ref) previous_end
 from work_logs w join people c on c.id=w.person_id where w.status='present' and w.end_min is not null) x
 where extract(epoch from (starts_at-previous_end))/60<(select value from settings where key='rest_minutes');
create view v_progress as
 select p.ref,p.name,p.status,count(s.id) filter(where s.status<>'cut') scenes,
 count(s.id) filter(where s.status='shot') shot,
 count(s.id) filter(where s.status='planned' and s.day_id is null) unscheduled,
 count(s.id) filter(where s.status='planned' and d.shoot_date<current_date) missed,
 coalesce(sum(s.eighths) filter(where s.status='shot'),0) shot_eighths,
 coalesce(sum(s.eighths) filter(where s.status<>'cut'),0) total_eighths
 from productions p left join scenes s on s.production_id=p.id left join shoot_days d on d.id=s.day_id group by p.id;
create view v_attention as
 select 1 priority,shoot_day ref,'Safety records' category,issue detail from v_compliance where shoot_date>=current_date-7
 union all select 1,scene,'Cast coverage',person||': '||booking_status||' for '||shoot_day from v_cast_gaps where shoot_date>=current_date
 union all select 1,first_day,'Crew clash',person||' also booked on '||second_day from v_conflicts where shoot_date>=current_date-1
 union all select 1,first_day,'Location clash',location||' also booked on '||second_day from v_location_conflicts where shoot_date>=current_date-1
 union all select 2,ref,'Hours',person||': '||flag from v_hours where flag in ('missing wrap','long day policy')
 union all select 2,ref,'Rest policy',person||': '||rest_minutes||' minutes between recorded shifts' from v_rest_gaps
 union all select 2,ref,'Missed scene',name||' planned on '||shoot_date::text from v_scene_plan where status='planned' and shoot_date<current_date
 union all select 3,ref,'Unscheduled scene',name from v_scene_plan where status='planned' and shoot_day is null
 union all select 2,ref,'Day capacity',planned_minutes||' scene minutes exceed '||(end_min-start_min)||' available minutes' from v_schedule where planned_minutes>end_min-start_min
 union all select 2,b.ref,'Missing hours',p.name||' has no working-hours record for '||d.ref from bookings b join shoot_days d on d.id=b.day_id join people p on p.id=b.person_id
 where b.status='confirmed' and d.shoot_date<current_date and not exists(select 1 from work_logs w where w.production_id=d.production_id and w.person_id=b.person_id and w.work_date=d.shoot_date);
