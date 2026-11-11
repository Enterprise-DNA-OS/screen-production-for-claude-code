do $$ declare p uuid; q uuid; loc uuid; studio uuid; a uuid;b uuid;c uuid;d uuid;past uuid;tom uuid;otherday uuid;s uuid;begin
if exists(select 1 from productions where ref='P-101') then return;end if;
if exists(select 1 from productions) then raise exception 'Demo seed requires an empty database';end if;
insert into productions(ref,name,status) values('P-101','Harbour Light','shooting') returning id into p;
insert into productions(ref,name,status) values('P-102','Winter Orchard Commercial','prep') returning id into q;
insert into locations(ref,name,address,permission_until,emergency_plan) values('L-101','Wharf Warehouse','14 Demo Wharf, Wellington',current_date-1,'') returning id into loc;
insert into locations(ref,name,address,permission_until,emergency_plan) values('L-102','Studio Two','8 Example Lane, Wellington',current_date+60,'EP-22: assembly at north gate, first aid in stage office') returning id into studio;
insert into people(ref,name,kind,department) values('C-101','Mara Cole','cast','Cast') returning id into a;
insert into people(ref,name,kind,department) values('C-102','Theo Lane','cast','Cast') returning id into b;
insert into people(ref,name,department) values('W-101','Alex Morgan','Camera') returning id into c;
insert into people(ref,name,department) values('W-102','Alex Reed','Sound') returning id into d;
insert into people(ref,name,department) values('W-103','Nia Bell','Production'),('W-104','Ben Lake','Lighting');
insert into shoot_days(ref,production_id,location_id,shoot_date,start_min,end_min,safety_contact,assessment_ref,briefing)
values('D-101',p,studio,current_date-1,420,1140,'Nia Bell','RA-101','Cable routes checked before call') returning id into past;
insert into shoot_days(ref,production_id,location_id,shoot_date,start_min,end_min)
values('D-102',p,loc,current_date+1,420,1080) returning id into tom;
insert into shoot_days(ref,production_id,location_id,shoot_date,start_min,end_min,safety_contact,assessment_ref,briefing)
values('D-103',q,studio,current_date+1,480,1020,'Nia Bell','RA-103','Studio exits remain clear') returning id into otherday;
insert into scenes(ref,production_id,name,location_id,day_id,eighths,duration_min,status) values('S-101',p,'Kitchen goodbye',studio,past,12,90,'shot');
insert into scenes(ref,production_id,name,location_id,day_id,eighths,duration_min) values('S-102',p,'Missed insert',studio,past,2,30);
insert into scenes(ref,production_id,name,location_id,day_id,eighths,duration_min) values('S-103',p,'Wharf reunion',loc,tom,16,180) returning id into s;
insert into scene_cast(ref,scene_id,person_id,character_name) values('SC-101',s,a,'June'),('SC-102',s,b,'Leo');
insert into scenes(ref,production_id,name,location_id,eighths,duration_min) values('S-104',p,'Night exterior',loc,8,120);
insert into scenes(ref,production_id,name,location_id,day_id,eighths,duration_min) values('S-201',q,'Product close-up',studio,otherday,4,60);
insert into bookings(ref,day_id,person_id,role,start_min,end_min,status) values
('B-101',tom,a,'June',420,1080,'tentative'),('B-102',tom,c,'Camera',420,1080,'confirmed'),
('B-103',otherday,c,'Camera',480,1020,'confirmed'),('B-104',past,c,'Camera',420,1140,'confirmed'),('B-105',past,d,'Sound',420,1140,'confirmed');
insert into risks(ref,day_id,description,controls,owner,review_due,status) values
('R-101',tom,'Public access beside working wharf','','',current_date-2,'open'),
('R-102',otherday,'Cable crossing','Cover crossing and inspect before call','Nia Bell',current_date+7,'controlled');
insert into work_logs(ref,production_id,person_id,work_date,start_min,end_min,break_min) values
('H-101',p,c,current_date-2,600,1320,30),('H-102',p,c,current_date-1,420,1260,30),('H-103',p,a,current_date-1,480,null,0);
insert into notes(ref,production_id,body) values('N-101',p,'Demo: location permission renewal is still with the production office.');
end $$;
