// Ensaio local de recuperação; dados nunca são enviados a outro serviço.
import {PGlite} from '@electric-sql/pglite';
import fs from 'node:fs';
import assert from 'node:assert/strict';
import {gerarRecuperacao,tabelas as base,tabelasInsumos,linhasSQL} from './snapshot-para-sql.mjs';
const input=process.argv[2];if(!input)throw Error('Informe o caminho da cópia JSON.');
const data=JSON.parse(fs.readFileSync(input,'utf8').replace(/^\uFEFF/,''));
const tabelas=data.versao===2?[...base,...tabelasInsumos]:base;
const sql=gerarRecuperacao(data),db=new PGlite();
await db.exec(fs.readFileSync('restore-fixture.sql','utf8'));
for(const p of data.perfis)await db.query('INSERT INTO auth.users VALUES($1)',[p.id]);
await db.exec(fs.readFileSync('fase1-estrutura-recuperacao.sql','utf8'));
if(data.versao===2){await db.exec(fs.readFileSync('fase1-fechamento.sql','utf8'));await db.exec(fs.readFileSync('insumos-estrutura-recuperacao.sql','utf8'));}
await db.exec(sql);
const canon=x=>JSON.stringify(x,(_k,v)=>v&&typeof v==='object'&&!Array.isArray(v)?Object.fromEntries(Object.keys(v).sort().map(k=>[k,v[k]])):v);
for(const t of tabelas){const {rows}=await db.query(`SELECT (SELECT coalesce(jsonb_agg(to_jsonb(t) ORDER BY to_jsonb(t)::text),'[]') FROM ${t} t)=(SELECT coalesce(jsonb_agg(to_jsonb(t) ORDER BY to_jsonb(t)::text),'[]') FROM jsonb_populate_recordset(NULL::${t},${linhasSQL(t,data)}) t) confere`);assert.equal(rows[0].confere,true,t);}
assert.equal((await db.query("SELECT tgenabled FROM pg_trigger WHERE tgname='fdm_validar'")).rows[0].tgenabled,'O');
assert.ok(Number((await db.query("SELECT nextval('pedidos_numero_seq') n")).rows[0].n)>Math.max(0,...data.pedidos.map(x=>Number(x.numero))));
console.log('Cópia baixada: '+tabelas.length+' tabelas recuperadas e comparadas; gatilhos reativados; numeração preservada.');
console.log(JSON.stringify(Object.fromEntries(tabelas.map(t=>[t,data[t].length]))));
await db.close();
