import { env } from 'cloudflare:workers';
import initial from '@/lib/initial-data.json';
import { validateMonth } from '@/lib/model';
const db=()=>env.DB;
export async function GET(){
 try {
  const {results}=await db().prepare('SELECT month, payload FROM reports').all<{month:string;payload:string}>();
  const merged=new Map(initial.map(m=>[m.month,m]));
  for(const row of results) merged.set(row.month,JSON.parse(row.payload));
  return Response.json([...merged.values()].sort((a,b)=>a.month.localeCompare(b.month)),{headers:{'Cache-Control':'no-store'}});
 }catch {return Response.json({error:'No fue posible cargar los datos guardados. Intenta nuevamente.'},{status:503});}
}
export async function POST(request:Request){
 if(request.headers.get('origin')!==new URL(request.url).origin) return Response.json({error:'Origen no permitido'},{status:403});
 try {
  const body=await request.text(); if(body.length>200000) return Response.json({error:'El informe es demasiado grande.'},{status:413});
  let m; try {m=validateMonth(JSON.parse(body));}catch(e){return Response.json({error:e instanceof Error?e.message:'Datos inválidos'},{status:400});}
  await db().prepare('INSERT INTO reports (month,payload,updated_at) VALUES (?,?,?) ON CONFLICT(month) DO UPDATE SET payload=excluded.payload,updated_at=excluded.updated_at').bind(m.month,JSON.stringify(m),new Date().toISOString()).run();
  return Response.json({ok:true});
 } catch {return Response.json({error:'No se pudo guardar. Tus cambios siguen en el formulario; vuelve a intentarlo.'},{status:503});}
}
