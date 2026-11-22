const KEY='clf_db_v1',SQLJS='https://cdnjs.cloudflare.com/ajax/libs/sql.js/1.8.0/';
let db;
const qa=(s,p=[])=>{const st=db.prepare(s);st.bind(p);const r=[];while(st.step())r.push(st.getAsObject());st.free();return r};
const q1=(s,p)=>qa(s,p)[0];
const qr=(s,p=[])=>{db.run(s,p);const n=db.getRowsModified(),id=qa('SELECT last_insert_rowid() id')[0].id;save();return{id,n}};
function save(){const b=db.export();let s='';for(let i=0;i<b.length;i+=8192)s+=String.fromCharCode.apply(null,b.subarray(i,i+8192));
 try{localStorage.setItem(KEY,btoa(s))}catch(e){}db.run('PRAGMA foreign_keys=ON')}
async function initDB(){const SQL=await initSqlJs({locateFile:f=>SQLJS+f}),saved=localStorage.getItem(KEY);
 if(saved){db=new SQL.Database(Uint8Array.from(atob(saved),c=>c.charCodeAt(0)));db.run('PRAGMA foreign_keys=ON')}
 else{db=new SQL.Database();const r=await fetch('schema.sql');if(!r.ok)throw new Error('schema.sql not found');db.exec(await r.text());save()}}
function resetDemo(){if(confirm('Reset all data back to the original demo data?')){localStorage.removeItem(KEY);sessionStorage.clear();location.reload()}}
const hx=a=>[...new Uint8Array(a)].map(x=>x.toString(16).padStart(2,'0')).join(''),te=new TextEncoder();
async function pb(pw,salt){const k=await crypto.subtle.importKey('raw',te.encode(pw),'PBKDF2',false,['deriveBits']);return hx(await crypto.subtle.deriveBits({name:'PBKDF2',salt:te.encode(salt),iterations:100000,hash:'SHA-256'},k,256))}
const hashPw=async p=>{const s=hx(crypto.getRandomValues(new Uint8Array(8)));return s+':'+await pb(p,s)};
const verifyPw=async(p,h)=>{const[s,k]=String(h).split(':');return!!k&&await pb(p,s)===k};
const lg=(u,a,d)=>qr('INSERT INTO activity_logs(user_id,action,details) VALUES(?,?,?)',[u,a,String(d||'').slice(0,250)]);
const nt=(u,t,m)=>qr('INSERT INTO notifications(user_id,title,message) VALUES(?,?,?)',[u,t,String(m).slice(0,490)]);
const ITEMS=`SELECT i.*,c.name category,l.name location,p.full_name reporter FROM items i JOIN categories c ON c.id=i.category_id JOIN locations l ON l.id=i.location_id JOIN student_profiles p ON p.user_id=i.reported_by`;
const RPT={items:[`SELECT i.id,i.type,i.title,c.name category,l.name location,i.event_date,i.status,p.full_name reporter,i.created_at FROM items i JOIN categories c ON c.id=i.category_id JOIN locations l ON l.id=i.location_id JOIN student_profiles p ON p.user_id=i.reported_by`,'i.created_at'],
 claims:[`SELECT c.id,i.title item,p.full_name claimant,c.status,c.admin_note,c.created_at,c.reviewed_at FROM claims c JOIN items i ON i.id=c.item_id JOIN student_profiles p ON p.user_id=c.claimant_id`,'c.created_at'],
 students:[`SELECT p.student_id,p.full_name,u.email,p.department,u.status,(SELECT COUNT(*) FROM items WHERE reported_by=u.id) reports,u.created_at FROM users u JOIN student_profiles p ON p.user_id=u.id WHERE u.role='student'`,'u.created_at']};
const toCsv=rows=>{if(!rows.length)return'';const k=Object.keys(rows[0]);return[k.join(','),...rows.map(r=>k.map(c=>{let v=String(r[c]??'');if(/^[=+\-@]/.test(v))v="'"+v;return'"'+v.replace(/"/g,'""')+'"'}).join(','))].join('\n')};

async function api(p,o={}){
 const m=(o.method||'GET').toUpperCase(),u=new URL(p,'http://x'),path=u.pathname,Q=Object.fromEntries(u.searchParams),B=o.body||{},U=S.user;let x;
 const is=(me,re)=>m===me&&!!(x=path.match(re));
 const need=r=>{if(!U)throw new Error('Please sign in');const c=q1('SELECT status FROM users WHERE id=?',[U.id]);if(!c||c.status!=='active')throw new Error('Account unavailable');if(r&&U.role!==r)throw new Error('Forbidden')};
 const login=async role=>{const e=(B.email||'').toLowerCase(),r=q1('SELECT u.*,p.full_name FROM users u JOIN student_profiles p ON p.user_id=u.id WHERE u.email=? AND u.role=?',[e,role]);
  if(!r||!(await verifyPw(B.password||'',r.password_hash)))throw new Error('Invalid email or password');if(r.status!=='active')throw new Error('This account is suspended');
  lg(r.id,'LOGIN',role+' login');return{token:String(r.id),user:{id:r.id,email:r.email,role:r.role,name:r.full_name}}};
 try{
 // ---------- auth ----------
 if(is('POST',/^\/auth\/login$/))return login('student');
 if(is('POST',/^\/auth\/admin-login$/))return login('admin');
 if(is('POST',/^\/auth\/register$/)){const{full_name,student_id,email,password,department,phone}=B;
  if(!full_name||!student_id||!/^\S+@\S+\.\S+$/.test(email||'')||(password||'').length<8)throw new Error('Name, student ID, valid email and an 8+ character password are required');
  if(q1('SELECT 1 x FROM users WHERE email=?',[email.toLowerCase()])||q1('SELECT 1 x FROM student_profiles WHERE student_id=?',[student_id]))throw new Error('Email or student ID already registered');
  const id=qr('INSERT INTO users(email,password_hash) VALUES(?,?)',[email.toLowerCase(),await hashPw(password)]).id;
  qr('INSERT INTO student_profiles(user_id,student_id,full_name,department,phone) VALUES(?,?,?,?,?)',[id,student_id,full_name,department||null,phone||null]);
  nt(id,'Welcome','Welcome to Campus Lost & Found!');lg(id,'REGISTER',email);return{token:String(id),user:{id,email:email.toLowerCase(),role:'student',name:full_name}}}
 // ---------- shared / student ----------
 if(is('GET',/^\/meta$/)){need();return{categories:qa('SELECT * FROM categories ORDER BY name'),locations:qa('SELECT * FROM locations ORDER BY name')}}
 if(is('GET',/^\/me$/)){need();return q1('SELECT u.id,u.email,u.role,u.created_at,p.* FROM users u JOIN student_profiles p ON p.user_id=u.id WHERE u.id=?',[U.id])}
 if(is('PUT',/^\/profile$/)){need();if(!B.full_name)throw new Error('Name is required');qr('UPDATE student_profiles SET full_name=?,department=?,year_of_study=?,phone=? WHERE user_id=?',[B.full_name,B.department||null,B.year_of_study||null,B.phone||null,U.id]);lg(U.id,'PROFILE_UPDATE','Profile updated');return{ok:1}}
 if(is('PUT',/^\/password$/)){need();if((B.next||'').length<8)throw new Error('New password must be at least 8 characters');
  if(!(await verifyPw(B.current||'',q1('SELECT password_hash FROM users WHERE id=?',[U.id]).password_hash)))throw new Error('Current password is incorrect');
  qr('UPDATE users SET password_hash=? WHERE id=?',[await hashPw(B.next),U.id]);lg(U.id,'PASSWORD_CHANGE','Password changed');return{ok:1}}
 if(is('GET',/^\/stats$/)){need('student');const id=U.id;
  const c=q1(`SELECT (SELECT COUNT(*) FROM items WHERE reported_by=? AND type='lost') myLost,(SELECT COUNT(*) FROM items WHERE reported_by=? AND type='found') myFound,(SELECT COUNT(*) FROM claims WHERE claimant_id=? AND status='pending') pendingClaims,(SELECT COUNT(*) FROM claims WHERE claimant_id=? AND status='approved') approvedClaims,(SELECT COUNT(*) FROM items WHERE status='approved') openItems,(SELECT COUNT(*) FROM items WHERE status IN('claimed','returned')) recovered`,[id,id,id,id]);
  return{c,recent:qa(ITEMS+` WHERE i.status='approved' ORDER BY i.created_at DESC LIMIT 5`)}}
 if(is('GET',/^\/items$/)){need();const w=[`i.status='approved'`],a=[];
  if(Q.q){w.push('(i.title LIKE ? OR i.description LIKE ?)');a.push(`%${Q.q}%`,`%${Q.q}%`)}
  if(['lost','found'].includes(Q.type)){w.push('i.type=?');a.push(Q.type)}
  if(Q.category){w.push('i.category_id=?');a.push(+Q.category)}if(Q.location){w.push('i.location_id=?');a.push(+Q.location)}
  return qa(ITEMS+' WHERE '+w.join(' AND ')+' ORDER BY i.created_at DESC LIMIT 200',a)}
 if(is('POST',/^\/items$/)){need('student');const{type,title,description,category_id,location_id,event_date}=B;
  if(!['lost','found'].includes(type)||!title||!description||!category_id||!location_id||!/^\d{4}-\d{2}-\d{2}$/.test(event_date||''))throw new Error('All fields are required');
  const id=qr('INSERT INTO items(type,title,description,category_id,location_id,event_date,reported_by) VALUES(?,?,?,?,?,?,?)',[type,title.slice(0,120),description,+category_id,+location_id,event_date,U.id]).id;
  lg(U.id,'REPORT_ITEM',`${type}: ${title}`);nt(U.id,'Report submitted',`Your ${type} report "${title}" is awaiting admin review.`);return{id}}
 if(is('GET',/^\/my\/items$/)){need('student');return qa(ITEMS+' WHERE i.reported_by=? ORDER BY i.created_at DESC, i.id DESC',[U.id])}
 if(is('DELETE',/^\/my\/items\/(\d+)$/)){need('student');const r=qr(`DELETE FROM items WHERE id=? AND reported_by=? AND status IN('pending','rejected')`,[+x[1],U.id]);if(!r.n)throw new Error('Only pending or rejected reports can be deleted');return{ok:1}}
 if(is('POST',/^\/claims$/)){need('student');if((B.proof||'').trim().length<10)throw new Error('Please describe proof of ownership (10+ characters)');
  const it=q1('SELECT * FROM items WHERE id=?',[+B.item_id]);if(!it||it.status!=='approved')throw new Error('This item is not open for claims');if(it.reported_by===U.id)throw new Error('You cannot claim your own report');
  if(q1('SELECT 1 x FROM claims WHERE item_id=? AND claimant_id=?',[it.id,U.id]))throw new Error('You have already claimed this item');
  qr('INSERT INTO claims(item_id,claimant_id,proof) VALUES(?,?,?)',[it.id,U.id,B.proof]);lg(U.id,'CLAIM_SUBMIT',it.title);nt(it.reported_by,'New claim on your report',`Someone submitted a claim for "${it.title}". Admin will review it.`);return{ok:1}}
 if(is('GET',/^\/my\/claims$/)){need('student');return qa('SELECT c.*,i.title,i.type FROM claims c JOIN items i ON i.id=c.item_id WHERE c.claimant_id=? ORDER BY c.created_at DESC, c.id DESC',[U.id])}
 // ---------- admin ----------
 if(is('GET',/^\/admin\/stats$/)){need('admin');
  const c=q1(`SELECT (SELECT COUNT(*) FROM users WHERE role='student') students,(SELECT COUNT(*) FROM items) items,(SELECT COUNT(*) FROM items WHERE type='lost') lost,(SELECT COUNT(*) FROM items WHERE type='found') found,(SELECT COUNT(*) FROM items WHERE status='pending') pendingItems,(SELECT COUNT(*) FROM claims WHERE status='pending') pendingClaims,(SELECT COUNT(*) FROM items WHERE status IN('claimed','returned')) recovered`);
  return{c,byCat:qa(`SELECT c.name label,COUNT(i.id) n FROM categories c LEFT JOIN items i ON i.category_id=c.id GROUP BY c.id`),byStatus:qa('SELECT status label,COUNT(*) n FROM items GROUP BY status'),
   byLoc:qa('SELECT l.name label,COUNT(*) n FROM items i JOIN locations l ON l.id=i.location_id GROUP BY l.id ORDER BY n DESC LIMIT 6'),
   monthly:qa(`SELECT strftime('%Y-%m',event_date) m,SUM(type='lost') lost,SUM(type='found') found FROM items GROUP BY m ORDER BY m DESC LIMIT 6`).reverse(),
   logs:qa('SELECT l.*,p.full_name who FROM activity_logs l LEFT JOIN student_profiles p ON p.user_id=l.user_id ORDER BY l.id DESC LIMIT 6')}}
 if(is('GET',/^\/admin\/students$/)){need('admin');return qa(`SELECT u.id,u.email,u.status,u.created_at,p.student_id,p.full_name,p.department,p.year_of_study,p.phone,(SELECT COUNT(*) FROM items WHERE reported_by=u.id) reports FROM users u JOIN student_profiles p ON p.user_id=u.id WHERE u.role='student' ORDER BY u.id`)}
 if(is('PATCH',/^\/admin\/students\/(\d+)$/)){need('admin');if(!['active','suspended'].includes(B.status))throw new Error('Invalid status');qr(`UPDATE users SET status=? WHERE id=? AND role='student'`,[B.status,+x[1]]);lg(U.id,'STUDENT_STATUS',`User ${x[1]} -> ${B.status}`);return{ok:1}}
 if(is('DELETE',/^\/admin\/students\/(\d+)$/)){need('admin');qr(`DELETE FROM users WHERE id=? AND role='student'`,[+x[1]]);lg(U.id,'STUDENT_DELETE','User '+x[1]);return{ok:1}}
 if(is('GET',/^\/admin\/items$/)){need('admin');return qa(ITEMS+(Q.status?' WHERE i.status=?':'')+' ORDER BY i.created_at DESC, i.id DESC',Q.status?[Q.status]:[])}
 if(is('PATCH',/^\/admin\/items\/(\d+)$/)){need('admin');if(!['approved','rejected','claimed','returned','pending'].includes(B.status))throw new Error('Invalid status');
  qr('UPDATE items SET status=?,admin_note=? WHERE id=?',[B.status,B.admin_note||null,+x[1]]);lg(U.id,'ITEM_REVIEW',`Item ${x[1]} -> ${B.status}`);return{ok:1}}
 if(is('DELETE',/^\/admin\/items\/(\d+)$/)){need('admin');qr('DELETE FROM items WHERE id=?',[+x[1]]);lg(U.id,'ITEM_DELETE','Item '+x[1]);return{ok:1}}
 if(is('GET',/^\/admin\/claims$/)){need('admin');return qa(`SELECT c.*,i.title,i.type,p.full_name claimant,p.student_id FROM claims c JOIN items i ON i.id=c.item_id JOIN student_profiles p ON p.user_id=c.claimant_id ORDER BY (c.status='pending') DESC,c.created_at DESC,c.id DESC`)}
 if(is('PATCH',/^\/admin\/claims\/(\d+)$/)){need('admin');const st=B.status,note=B.admin_note||null;if(!['approved','rejected'].includes(st))throw new Error('Invalid status');
  const c=q1(`SELECT c.*,i.title FROM claims c JOIN items i ON i.id=c.item_id WHERE c.id=? AND c.status='pending'`,[+x[1]]);if(!c)throw new Error('Claim not found or already reviewed');
  qr(`UPDATE claims SET status=?,admin_note=?,reviewed_at=datetime('now') WHERE id=?`,[st,note,c.id]);
  if(st==='approved'){qr(`UPDATE items SET status='claimed' WHERE id=?`,[c.item_id]);const o=qa(`SELECT claimant_id FROM claims WHERE item_id=? AND status='pending'`,[c.item_id]);
   qr(`UPDATE claims SET status='rejected',admin_note='Another claim was approved',reviewed_at=datetime('now') WHERE item_id=? AND status='pending'`,[c.item_id]);
   o.forEach(r=>nt(r.claimant_id,'Claim rejected',`Your claim for "${c.title}" was not approved because another claim was verified.`))}
  nt(c.claimant_id,'Claim '+st,`Your claim for "${c.title}" was ${st}.${note?' Note: '+note:''}`);lg(U.id,'CLAIM_REVIEW',`Claim ${c.id} -> ${st}`);return{ok:1}}
 if(x=path.match(/^\/admin\/(categories|locations)(?:\/(\d+))?$/)){need('admin');const t=x[1],id=+x[2],col=t==='categories'?'category_id':'location_id';
  if(m==='GET')return qa(`SELECT x.*,(SELECT COUNT(*) FROM items WHERE ${col}=x.id) uses FROM ${t} x ORDER BY name`);
  if(m==='POST'){if(!(B.name||'').trim())throw new Error('Name is required');qr(`INSERT INTO ${t}(name,description) VALUES(?,?)`,[B.name.trim(),B.description||null]);lg(U.id,'ADD_'+t.toUpperCase(),B.name);return{ok:1}}
  if(m==='PUT'){qr(`UPDATE ${t} SET name=?,description=? WHERE id=?`,[B.name,B.description||null,id]);lg(U.id,'EDIT_'+t.toUpperCase(),B.name);return{ok:1}}
  if(m==='DELETE'){try{qr(`DELETE FROM ${t} WHERE id=?`,[id])}catch(e){throw new Error('Cannot delete: it is used by existing items')}lg(U.id,'DELETE_'+t.toUpperCase(),id);return{ok:1}}}
 if(is('GET',/^\/admin\/announcements$/)){need('admin');return qa('SELECT * FROM announcements ORDER BY created_at DESC, id DESC')}
 if(is('POST',/^\/admin\/announcements$/)){need('admin');if(!B.title||!B.body)throw new Error('Title and message are required');
  qr('INSERT INTO announcements(title,body,created_by) VALUES(?,?,?)',[B.title,B.body,U.id]);qr(`INSERT INTO notifications(user_id,title,message) SELECT id,?,? FROM users WHERE role='student' AND status='active'`,[B.title,B.body.slice(0,490)]);lg(U.id,'ANNOUNCEMENT',B.title);return{ok:1}}
 if(is('DELETE',/^\/admin\/announcements\/(\d+)$/)){need('admin');qr('DELETE FROM announcements WHERE id=?',[+x[1]]);return{ok:1}}
 if(is('GET',/^\/admin\/logs$/)){need('admin');return qa(`SELECT l.*,COALESCE(p.full_name,'(deleted user)') who,u.role FROM activity_logs l LEFT JOIN student_profiles p ON p.user_id=l.user_id LEFT JOIN users u ON u.id=l.user_id ORDER BY l.id DESC LIMIT 300`)}
 if(is('GET',/^\/admin\/report\/(\w+)$/)){need('admin');const r=RPT[x[1]];if(!r)throw new Error('Unknown report');
  const rows=qa(r[0]+(r[0].includes(' WHERE ')?' AND ':' WHERE ')+`date(${r[1]}) BETWEEN ? AND ?`,[Q.from||'2000-01-01',Q.to||'2999-12-31']);lg(U.id,'REPORT_EXPORT',x[1]);
  return Q.format==='csv'?{csv:toCsv(rows)}:rows}
 }catch(e){throw new Error(/UNIQUE/.test(e.message)?'Already exists':/FOREIGN KEY/.test(e.message)?'Cannot complete: linked to existing data':e.message)}
 throw new Error('Not found: '+path);
}
