export type Row = { entity: string; debtor: number; codebtor: number; identity?: number; campaigns?: number; messages?: number };
export type Month = {month: string; source: string; rows: Row[]};
export const months = Array.from({length:12},(_,i)=>`${i<10?2026:2027}-${String((i+2)%12+1).padStart(2,'0')}`);
export const label=(m:string)=>new Date(m+'-15T12:00:00').toLocaleDateString('es-CO',{month:'long',year:'numeric'});
export const total=(m:Month)=>m.rows.reduce((s,r)=>s+r.debtor+r.codebtor,0);
export function validateMonth(value: unknown): Month {
 const m=value as Month;
 if(!m || !months.includes(m.month) || typeof m.source!=='string' || !m.source.trim() || m.source.length>200 || !Array.isArray(m.rows) || !m.rows.length || m.rows.length>500) throw new Error('Selecciona un mes de la vigencia, indica la fuente y agrega al menos una entidad.');
 const names=new Set<string>();
 for(const r of m.rows){
  if(typeof r.entity!=='string'||!r.entity.trim()||r.entity.length>100||![r.debtor,r.codebtor,r.identity??0,r.campaigns??0,r.messages??0].every(n=>Number.isSafeInteger(n)&&n>=0&&n<=1000000)) throw new Error('Cada entidad necesita un nombre y cantidades enteras entre 0 y 1.000.000.');
  r.entity=r.entity.trim().toUpperCase(); if(names.has(r.entity)) throw new Error('Hay entidades repetidas. Combina sus cantidades en una sola fila.'); names.add(r.entity);
 }
 return {month:m.month,source:m.source.trim(),rows:m.rows.map(r=>({entity:r.entity,debtor:r.debtor,codebtor:r.codebtor,identity:r.identity??0,campaigns:r.campaigns??0,messages:r.messages??0}))};
}

export const extraFields = [{key:'identity',label:'Validación de identidad'},{key:'campaigns',label:'Campañas'},{key:'messages',label:'Mensajes'}] as const;
export function otherCharges(data:Month[], names:string[], period:string, entity:string){
 return names.filter(name=>entity==='all'||name===entity).map(name=>{
  const result={entity:name,identity:0,campaigns:0,messages:0};
  for(const month of data.filter(m=>period==='all'||m.month===period)){
   const row=month.rows.find(r=>r.entity===name);
   for(const {key} of extraFields) result[key]+=row?.[key]??0;
  }
  return result;
 }).sort((a,b)=>(b.identity+b.campaigns+b.messages)-(a.identity+a.campaigns+a.messages)||a.entity.localeCompare(b.entity));
}
