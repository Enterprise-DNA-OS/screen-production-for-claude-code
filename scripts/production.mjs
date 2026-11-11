#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { getDb, REPO_ROOT } from './lib/db.mjs';
import { parseCsv, pick } from './lib/csv.mjs';
import { table } from './lib/format.mjs';
import { page, table as htmlTable, writeOut } from './lib/render.mjs';

export const entities = {
 production: {table:'productions', fields:['ref','name','status']},
 location: {table:'locations', fields:['ref','name','address','permission_until','emergency_plan']},
 person: {table:'people', fields:['ref','name','kind','department']},
 day: {table:'shoot_days', fields:['ref','production_id','location_id','shoot_date','unit','start_min','end_min','safety_contact','assessment_ref','briefing']},
 scene: {table:'scenes', fields:['ref','production_id','name','location_id','day_id','eighths','duration_min','order_no','status']},
 cast: {table:'scene_cast', fields:['ref','scene_id','person_id','character_name']},
 booking: {table:'bookings', fields:['ref','day_id','person_id','role','start_min','end_min','status']},
 risk: {table:'risks', fields:['ref','day_id','description','controls','owner','review_due','status']},
 hours: {table:'work_logs', fields:['ref','production_id','person_id','work_date','status','start_min','end_min','break_min']},
 note: {table:'notes', fields:['ref','production_id','body']},
};
const fk = {production_id:'production',location_id:'location',day_id:'day',person_id:'person',scene_id:'scene'};
const alias = {production:'production_id',location:'location_id',day:'day_id',person:'person_id',scene:'scene_id',start:'start_min',end:'end_min',break:'break_min'};
const reads = {
 productions:'select ref,name,status from productions order by ref',
 people:'select ref,name,kind,department from people order by ref',
 locations:'select ref,name,address,permission_until,emergency_plan from locations order by ref',
 'shoot-week':'select ref,production,shoot_date,unit,location,scenes,planned_minutes,confirmed_people from v_schedule where shoot_date between current_date and current_date+7 order by shoot_date,ref',
 schedule:'select ref,production,shoot_date,unit,location,start_min,end_min,scenes,planned_minutes from v_schedule order by shoot_date,ref',
 scenes:'select ref,production,name,shoot_day,shoot_date,eighths,status from v_scene_plan order by production,shoot_date,order_no,ref',
 'cast-gaps':'select shoot_day,scene,person,character_name,booking_status from v_cast_gaps order by shoot_date,scene,person',
 'crew-clashes':'select person,first_day,second_day,shoot_date from v_conflicts order by shoot_date,person',
 'location-clashes':'select * from v_location_conflicts order by shoot_date,first_day',
 'day-out-of-days':`select p.ref person_ref,p.name person,pr.ref production,d.shoot_date,string_agg(distinct sc.character_name,', ') characters,string_agg(distinct s.ref,', ') scenes,coalesce(b.status,'not booked') booking from scene_cast sc join people p on p.id=sc.person_id join scenes s on s.id=sc.scene_id join shoot_days d on d.id=s.day_id join productions pr on pr.id=s.production_id left join bookings b on b.day_id=d.id and b.person_id=p.id where s.status<>'cut' group by p.ref,p.name,pr.ref,d.shoot_date,b.status order by d.shoot_date,p.name`,
 bookings:`select b.ref,d.ref shoot_day,p.name person,b.role,b.start_min,b.end_min,b.status from bookings b join shoot_days d on d.id=b.day_id join people p on p.id=b.person_id order by d.shoot_date,b.ref`,
 risks:`select r.ref,d.ref shoot_day,r.description,r.controls,r.owner,r.review_due,r.status from risks r join shoot_days d on d.id=r.day_id order by r.review_due,r.ref`,
 'work-hours':'select ref,production,person,work_date,status,start_min,end_min,worked_minutes,flag from v_hours order by work_date,ref',
 'rest-gaps':'select * from v_rest_gaps order by work_date,person',
 'wrap-report':'select * from v_progress order by ref',
 attention:'select * from v_attention order by priority,category,ref,detail',
 compliance:'select shoot_day,shoot_date,rule,issue,source from v_compliance order by shoot_date,shoot_day,rule',
 notes:'select n.ref,p.ref production,n.body,n.created_at from notes n join productions p on p.id=n.production_id order by n.created_at,n.ref',
 audit:'select entity,record_id,action,actor,created_at from audit_events order by created_at desc,id limit 100',
};
function parse(args){
 const pos=[],opts={};for(const a of args){if(!a.startsWith('--')){pos.push(a);continue;}const i=a.indexOf('=');const k=a.slice(2,i<0?undefined:i);if(Object.hasOwn(opts,k))throw Error(`Repeated option --${k}`);opts[k]=i<0?true:a.slice(i+1);}return {pos,opts};
}
const required=(v,label)=>{if(typeof v!=='string'||!v.trim())throw Error(`${label} is required`);return v.trim();};
function dayDate(v){if(!/^\d{4}-\d{2}-\d{2}$/.test(v)||new Date(v+'T00:00:00Z').toISOString().slice(0,10)!==v)throw Error(`Invalid calendar date: ${v}`);return v;}
function integer(v){if(!/^\d+$/.test(String(v)))throw Error(`Expected a nonnegative integer: ${v}`);return Number(v);}
function minute(v){if(/^\d{1,2}:\d{2}$/.test(String(v))){const [h,m]=v.split(':').map(Number);if(h>48||m>59)throw Error(`Invalid clock time: ${v}`);return h*60+m;}return integer(v);}
export async function resolve(db,kind,value){
 const e=entities[kind];if(!e)throw Error(`Unknown entity ${kind}`);required(value,kind);
 const name=e.fields.includes('name')?'name':'ref';
 let rows=await db.query(`select id,ref,${name} label from ${e.table} where lower(ref)=lower($1) or id::text=$1`,[value]);
 if(!rows.length)rows=await db.query(`select id,ref,${name} label from ${e.table} where starts_with(id::text,lower($1)) or position(lower($1) in lower(${name}))>0 order by ref`,[value]);
 if(rows.length!==1)throw Error(rows.length?`Ambiguous ${kind} "${value}":\n${rows.map(r=>`${r.ref} ${r.label} ${r.id}`).join('\n')}`:`No ${kind} matches "${value}"`);
 return rows[0].id;
}
async function values(db,kind,opts){
 const e=entities[kind];if(!e)throw Error(`Unknown entity ${kind}`);const vals={};
 for(const [raw,value] of Object.entries(opts)){
 if(raw==='json')continue;const k=alias[raw]||raw.replaceAll('-','_');if(!e.fields.includes(k))throw Error(`Unknown ${kind} field ${raw}`);
 let v=value;if(v===true)throw Error(`--${raw} needs a value`);
 if(v==='null'){if(!['permission_until','day_id','start_min','end_min'].includes(k))throw Error(`${k} cannot be cleared`);v=null;}
 else if(fk[k])v=await resolve(db,fk[k],v);
 else if(k.endsWith('_date')||['permission_until','review_due'].includes(k))v=dayDate(v);
 else if(['start_min','end_min'].includes(k))v=minute(v);
 else if(k.endsWith('_min')||['eighths','order_no'].includes(k))v=integer(v);
 else v=required(v,raw);
 vals[k]=v;
 }
 if(!Object.keys(vals).length)throw Error('Supply fields as --field=value');return vals;
}
async function mutate(db,cmd,kind,idText,opts){
 const e=entities[kind];if(!e)throw Error(`Unknown entity ${kind}`);
 await db.exec('BEGIN');try {
 const v=await values(db,kind,opts),cols=Object.keys(v);
 let result;if(cmd==='add'){result=await db.query(`insert into ${e.table} (${cols.join(',')}) values (${cols.map((_,i)=>'$'+(i+1)).join(',')}) returning *`,Object.values(v));}
 else {const id=await resolve(db,kind,idText);result=await db.query(`update ${e.table} set ${cols.map((k,i)=>`${k}=$${i+1}`).join(',')} where id=$${cols.length+1} returning *`,[...Object.values(v),id]);}
 await db.exec('COMMIT');return result;
 }catch(e){await db.exec('ROLLBACK');throw e;}
}
function allowed(opts,keys){for(const k of Object.keys(opts))if(!['json',...keys].includes(k))throw Error(`Unknown option --${k}`);}
async function importDramatify(db,opts){
 allowed(opts,['file','production','date','mapping','dry-run']);
 const production=await resolve(db,'production',required(opts.production,'--production'));
 const date=dayDate(required(opts.date,'--date'));const file=required(opts.file,'--file');
 const rows=parseCsv(fs.readFileSync(file,'utf8'));if(!rows.length)throw Error('CSV has no data rows');
 const mapping=opts.mapping?JSON.parse(fs.readFileSync(opts.mapping,'utf8')):{};
 const keys=['person','first_name','last_name','start','end','status','break'];
 if(!mapping||Array.isArray(mapping)||typeof mapping!=='object')throw Error('Mapping must be an object');
 for(const [k,v] of Object.entries(mapping)){if(!keys.includes(k)||typeof v!=='string'||!Object.keys(rows[0]).includes(v))throw Error(`Mapping ${k} must name a column in this export`);}
 const defaults={person:['Person','Name','Full name'],first_name:['First name'],last_name:['Last name'],start:['Check in','Start','In'],end:['Check out','End','Out'],status:['Status','Attendance'],break:['Break minutes','Break']};
 const val=(r,k)=>mapping[k]?r[mapping[k]]:pick(r,...defaults[k]);
 const warnings=[];if(!mapping.break&&!defaults.break.some(h=>Object.keys(rows[0]).some(k=>k.toLowerCase()===h.toLowerCase())))warnings.push('No break column: zero deducted. Review working-hours totals against source.');
 const seen=new Set(),out=[];await db.exec('BEGIN');try{
 for(const [i,r] of rows.entries()){
 try{
 const name=val(r,'person')||`${val(r,'first_name')} ${val(r,'last_name')}`.trim();const person=await resolve(db,'person',required(name,'person'));
 if(seen.has(person))throw Error('Duplicate person in this daily export');seen.add(person);
 const rawStatus=val(r,'status').trim().toLowerCase();const status=({present:'present',worked:'present',sick:'sick','sick day':'sick',absent:'absent'})[rawStatus]||(!rawStatus&&val(r,'start')?'present':null);
 if(!status)throw Error(`Unknown attendance "${rawStatus}". Map status or retain the row for review.`);
 let start=null,end=null,breaks=0;
 if(status==='present'){start=minute(required(val(r,'start'),'check in'));end=val(r,'end')?minute(val(r,'end')):null;breaks=val(r,'break')?integer(val(r,'break')):0;
 if(end!==null&&end<=start)throw Error('Wrap precedes call. Confirm overnight work and express wrap as 24:00 or later.');}
 else if(val(r,'start')||val(r,'end')||Number(val(r,'break')||0)!==0)throw Error('Absent/sick row contains worked time');
 const ref=`DR-${production.slice(0,8)}-${person.slice(0,8)}-${date}`;
 const result=await db.query(`insert into work_logs(ref,production_id,person_id,work_date,status,start_min,end_min,break_min,source,source_row)
 values($1,$2,$3,$4,$5,$6,$7,$8,'dramatify',$9) on conflict(production_id,person_id,work_date) do update set
 status=excluded.status,start_min=excluded.start_min,end_min=excluded.end_min,break_min=excluded.break_min,source=excluded.source,source_row=excluded.source_row returning ref`,
 [ref,production,person,date,status,start,end,breaks,JSON.stringify(r)]);out.push({row:i+2,person:name,ref:result[0].ref,status});
 }catch(e){throw Error(`CSV row ${i+2}: ${e.message}`);}
 }
 await db.exec(opts['dry-run']?'ROLLBACK':'COMMIT');return {dry_run:Boolean(opts['dry-run']),rows:out.length,warnings,records:out};
 }catch(e){await db.exec('ROLLBACK');throw e;}
}
const csvCell=v=>`"${String(v??'').replaceAll('"','""')}"`;
async function exportAll(db,opts){
 allowed(opts,['out']);const dir=path.resolve(opts.out||path.join(REPO_ROOT,'exports',new Date().toISOString().replace(/[:.]/g,'-')));
 fs.mkdirSync(dir,{recursive:true,mode:0o700});const snapshot={format:'screen-production-v1',exported_at:new Date().toISOString(),tables:{}};
 await db.exec('BEGIN READ ONLY');try{
 for(const t of [...Object.values(entities).map(e=>e.table),'settings','audit_events']){
 const rows=await db.query(`select * from ${t} order by ${t==='settings'?'key':'id'}`);snapshot.tables[t]=rows;
 if(rows.length){const keys=Object.keys(rows[0]);const data=[keys.map(csvCell).join(','),...rows.map(r=>keys.map(k=>csvCell(typeof r[k]==='object'&&r[k]!==null?JSON.stringify(r[k]):r[k])).join(','))].join('\r\n')+'\r\n';fs.writeFileSync(path.join(dir,t+'.csv'),data,{mode:0o600,flag:'wx'});}
 }
 fs.writeFileSync(path.join(dir,'snapshot.json'),JSON.stringify(snapshot,null,2)+'\n',{mode:0o600,flag:'wx'});
 await db.exec('ROLLBACK');return {directory:dir,counts:Object.fromEntries(Object.entries(snapshot.tables).map(([k,v])=>[k,v.length]))};
 }catch(e){await db.exec('ROLLBACK');throw e;}
}
async function callSheet(db,needle){
 const id=await resolve(db,'day',needle);
 const day=(await db.query('select id,ref,production,title,shoot_date,unit,location,clock_time(start_min) as call,clock_time(end_min) as wrap,scenes,safety_contact,assessment_ref,briefing from v_schedule where id=$1',[id]))[0];if(!day)throw Error('Archived production has no active call sheet');
 return {day,scenes:await db.query('select ref,name,eighths,duration_min,status from v_scene_plan where shoot_day=$1 order by order_no,ref',[day.ref]),
 crew:await db.query(`select p.name,b.role,clock_time(b.start_min) as call,clock_time(b.end_min) as wrap,b.status from bookings b join people p on p.id=b.person_id where b.day_id=$1 order by b.start_min,p.name`,[id]),
 safety:await db.query('select rule,issue from v_compliance where day_id=$1',[id]),
 cast:await db.query('select scene,person,booking_status from v_cast_gaps where day_id=$1',[id]),
 risks:await db.query('select description,controls,owner,review_due,status from risks where day_id=$1',[id])};
}
const usage=`Screen Production CLI\n\nReads: ${Object.keys(reads).join(', ')}\ncall-sheet <day> | weekly-review | card <entity> <ref-or-name>\nadd <entity> --ref=... --field=value | set <entity> <ref-or-name> --field=value\nEntities: ${Object.keys(entities).join(', ')}\nschedule-scene <scene> --day=<day> | mark-shot <scene>\nlog <production> --text=...\ndraft-call-sheet <day> | draft-weekly-review\nimport dramatify --file=hours.csv --production=P-101 --date=YYYY-MM-DD [--mapping=map.json] [--dry-run]\nexport [--out=folder]\nAll commands accept --json. Times: HH:MM or integer minutes; overnight wrap explicitly uses 24:00 or later.\nRun npm run migrate first. Run npm run demo only in a disposable database.`;
export async function execute(db,args){
 const {pos,opts}=parse(args);const [cmd,kind,needle]=pos;
 if(cmd==='help'||!cmd)return {help:usage};
 if(reads[cmd]){allowed(opts,[]);if(pos.length>1)throw Error('Read command takes no positional filters');return db.query(reads[cmd]);}
 if(cmd==='add'||cmd==='set')return mutate(db,cmd,kind,needle,opts);
 if(cmd==='card'){allowed(opts,[]);const id=await resolve(db,kind,needle);return db.query(`select * from ${entities[kind].table} where id=$1`,[id]);}
 if(cmd==='schedule-scene'){allowed(opts,['day']);return mutate(db,'set','scene',kind,{day:required(opts.day,'--day')});}
 if(cmd==='mark-shot'){allowed(opts,[]);return mutate(db,'set','scene',kind,{status:'shot'});}
 if(cmd==='log'){allowed(opts,['text']);return mutate(db,'add','note',null,{ref:'N-'+crypto.randomUUID(),production:kind,body:required(opts.text,'--text')});}
 if(cmd==='import'){if(kind!=='dramatify')throw Error('Supported import: dramatify daily working-hours CSV');return importDramatify(db,opts);}
 if(cmd==='export')return exportAll(db,opts);
 if(cmd==='call-sheet'||cmd==='draft-call-sheet'){
 allowed(opts,[]);const sheet=await callSheet(db,kind);if(cmd==='call-sheet')return sheet;
 const sections=Object.entries(sheet).map(([k,v])=>({title:k,html:htmlTable(Array.isArray(v)?v:[v])}));
 return {file:writeOut('drafts',`call-sheet-${sheet.day.ref}-${Date.now()}`,page({title:'DRAFT call sheet',subtitle:'Production manager review required. Nothing sent.',sections}))};
 }
 if(cmd==='weekly-review'||cmd==='draft-weekly-review'){
 allowed(opts,[]);const sections={week:await db.query(reads['shoot-week']),attention:await db.query(reads.attention),progress:await db.query(reads['wrap-report'])};
 if(cmd==='weekly-review')return sections;
 return {file:writeOut('drafts',`weekly-review-${Date.now()}`,page({title:'DRAFT weekly production review',subtitle:'Review outstanding decisions before distribution.',sections:Object.entries(sections).map(([title,rows])=>({title,html:htmlTable(rows)}))}))};
 }
 throw Error(`Unknown command ${cmd}. Run help.`);
}
function human(result){if(Array.isArray(result)){if(!result.length)return '(none)';return table(result,Object.keys(result[0]).filter(k=>k!=='id').map(key=>({key,label:key.replaceAll('_',' ')})));}if(result.help)return result.help;
 return Object.entries(result).map(([k,v])=>`${k}\n${Array.isArray(v)?human(v):v&&typeof v==='object'?human([v]):v}`).join('\n\n');}
if(process.argv[1]&&import.meta.url===pathToFileURL(path.resolve(process.argv[1])).href){
 let db;try{const args=process.argv.slice(2);db=await getDb();const result=await execute(db,args);console.log(args.includes('--json')?JSON.stringify(result,null,2):human(result));}
 catch(e){console.error(e.message);process.exitCode=1;}finally{await db?.close();}
}
