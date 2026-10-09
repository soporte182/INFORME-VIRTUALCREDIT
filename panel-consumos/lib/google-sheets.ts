import {Month, validateMonth} from './model';

// Activar cuando se haya publicado y verificado la pestaña de datos.
export const sheetConfig = {csvUrl: 'https://docs.google.com/spreadsheets/d/1XjIdZBhhumkNUQ11slvYyxNHHfL7zY70/export?format=csv&gid=209671180', editUrl: 'https://docs.google.com/spreadsheets/d/1XjIdZBhhumkNUQ11slvYyxNHHfL7zY70/edit#gid=209671180'};
export const sheetsEnabled = Boolean(sheetConfig.csvUrl);

export function parseSheetCsv(text: string): Month[] {
 const records: string[][] = []; let row: string[] = [], cell = '', quoted = false;
 for(let i=0;i<text.length;i++) {
  const c=text[i];
  if(c==='"') {if(quoted && text[i+1]==='"'){cell+='"';i++;}else quoted=!quoted;}
  else if(!quoted && (c===',' || c==='\n' || c==='\r')) {
   row.push(cell);cell='';
   if(c!==','){records.push(row);row=[];if(c==='\r'&&text[i+1]==='\n')i++;}
  } else cell+=c;
 }
 if(quoted)throw Error('Hay una celda con comillas sin cerrar en la hoja.');
 if(cell || row.length){row.push(cell);records.push(row);}
 const clean=(s:string)=>s.replace(/^\uFEFF/,'').trim().normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase();
 const headers=(records.shift()??[]).map(clean);
 const aliases=[['entidad'],['deudor','analisis deudor'],['codeudor','analisis codeudor'],['validacion de identidad','validacion identidad'],['campanas'],['mensajes']];
 const columns=aliases.map(options=>headers.findIndex(h=>options.includes(h)));
 const monthColumn=headers.indexOf('mes'),yearColumn=headers.indexOf('ano'),numberColumn=headers.indexOf('mes numero');
 if(columns.some(i=>i<0) || (monthColumn<0&&(yearColumn<0||numberColumn<0)))throw Error('Revisa las columnas de entidad, análisis, identidad, campañas, mensajes y mes (o Año y Mes número).');
 const reports=new Map<string,Month>();
 records.forEach((values,index)=>{
  if(values.every(v=>!v.trim()))return;
  const fields=columns.map(i=>(values[i]??'').trim());
  const month=monthColumn>=0?(values[monthColumn]??'').trim():`${(values[yearColumn]??'').trim()}-${(values[numberColumn]??'').trim().padStart(2,'0')}`;
  const [entity]=fields;
  const counts=fields.slice(1).map((value)=>{
   if(!/^\d+$/.test(value))throw Error(`Fila ${index+2}: completa las cantidades con enteros sin puntos ni comas; usa 0 si no hay consumo.`);
   return Number(value);
  });
  const report=reports.get(month)??{month,source:'Google Sheets',rows:[]};
  report.rows.push({entity,debtor:counts[0],codebtor:counts[1],identity:counts[2],campaigns:counts[3],messages:counts[4]});
  reports.set(month,report);
 });
 if(!reports.size)throw Error('La hoja no contiene registros completos.');
 return [...reports.values()].map(validateMonth).sort((a,b)=>a.month.localeCompare(b.month));
}

export async function readGoogleSheet(): Promise<Month[]> {
 const response=await fetch(sheetConfig.csvUrl,{cache:'no-store',signal:AbortSignal.timeout(20000)});
 if(!response.ok)throw Error('No se pudo leer la hoja publicada.');
 return parseSheetCsv(await response.text());
}
