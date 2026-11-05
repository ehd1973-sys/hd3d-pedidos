// Ensaio local de recuperação; dados nunca são enviados a outro serviço.
import {PGlite} from '@electric-sql/pglite';
import fs from 'node:fs';
import assert from 'node:assert/strict';
import {gerarRecuperacao,tabelas} from './snapshot-para-sql.mjs';
const input=process.argv[2];if(!input)throw Error('Informe o caminho da cópia JSON.');
const data=JSON.parse(fs.readFileSync(input,'utf8').replace(/^\uFEFF/,''));
const sql=gerarRecuperacao(data),db=new PGlite();
await db.exec(fs.readFileSync('restore-fixture.sql','utf8'));
for(const p of data.perfis)await db.query('INSERT INTO auth.users VALUES($1)',[p.id]);
await db.exec(fs.readFileSync('fase1-estrutura-recuperacao.sql','utf8'));
await db.exec(sql);
const canon=x=>JSON.stringify(x,(_k,v)=>v&&typeof v==='object'&&!Array.isArray(v)?Object.fromEntries(Object.keys(v).sort().map(k=>[k,v[k]])):v);
for(const t of tabelas){const {rows}=await db.query('SELECT to_jsonb(t) r FROM '+t+' t');assert.deepEqual(rows.map(x=>canon(x.r)).sort(),data[t].map(canon).sort());}
assert.equal((await db.query("SELECT tgenabled FROM pg_trigger WHERE tgname='fdm_validar'")).rows[0].tgenabled,'O');
assert.ok(Number((await db.query("SELECT nextval('pedidos_numero_seq') n")).rows[0].n)>Math.max(0,...data.pedidos.map(x=>Number(x.numero))));
console.log('Cópia baixada: dez tabelas recuperadas e comparadas; gatilho reativado; numeração preservada.');
console.log(JSON.stringify(Object.fromEntries(tabelas.map(t=>[t,data[t].length]))));
await db.close();
