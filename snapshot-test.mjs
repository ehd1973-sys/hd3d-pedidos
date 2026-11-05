import {PGlite} from '@electric-sql/pglite';
import fs from 'node:fs';
import assert from 'node:assert/strict';
import {gerarRecuperacao,tabelas} from './snapshot-para-sql.mjs';
const read=f=>fs.readFileSync(f,'utf8');
const fixture=JSON.parse(read('fixture-teste.json'));
const db=new PGlite();await db.exec(read('restore-fixture.sql'));
for(const p of fixture.perfis)await db.query('INSERT INTO auth.users VALUES($1)',[p.id]);
for(const t of tabelas.slice(0,5))for(const row of fixture[t]){
 const keys=Object.keys(row);await db.query(`INSERT INTO ${t}(${keys.join(',')}) VALUES(${keys.map((_,i)=>'$'+(i+1)).join(',')})`,Object.values(row));
}
await db.exec(read('fase1.sql'));await db.exec(read('fase1-fechamento.sql'));
await db.exec('GRANT USAGE ON SCHEMA public,auth TO authenticated; GRANT SELECT ON public.pedidos,public.perfis TO authenticated;');
const uid=fixture.perfis[0].id,p=fixture.pedidos[0].id;
await db.query("SELECT set_config('request.jwt.claim.sub',$1,false)",[uid]);
await db.exec('SET ROLE authenticated');
const {rows:[i]}=await db.query("INSERT INTO impressoes(pedido_id,equipamento_id,material_id,inicio_em,fim_em,peso_peca_g,purga_g,desperdicio_g,observacoes) VALUES($1,'00000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000011','2026-11-05 10:00Z','2026-11-05 11:00Z',10,2,0,$2) RETURNING id",[p,"Recuperação d'água \\ <teste> $$"]);
await db.query("SELECT fdm_encerrar($1,'concluida')",[i.id]);await db.query('SELECT fdm_estornar($1)',[i.id]);
const data=(await db.query('SELECT fdm_exportar_snapshot() d')).rows[0].d;
assert.equal(data.impressoes[0].status,'estornada');assert.equal(data.movimentacoes_estoque.length,2);
await db.exec('RESET ROLE');
// Todos os perfis não master, inclusive financeiro e produção, são recusados.
for(const role of ['leitor','operador','financeiro','inativo']){
 await db.query('UPDATE perfis SET master=false,ativo=$1,producao=$2,ver_financeiro=$3 WHERE id=$4',[role!=='inativo',role==='operador',role==='financeiro',uid]);
 await db.exec('SET ROLE authenticated');await assert.rejects(db.query('SELECT fdm_exportar_snapshot()'));await db.exec('RESET ROLE');
}
await db.exec('SET ROLE anon');await assert.rejects(db.query('SELECT fdm_exportar_snapshot()'));await db.exec('RESET ROLE');
const destino=new PGlite();await destino.exec(read('restore-fixture.sql'));
for(const user of data.perfis)await destino.query('INSERT INTO auth.users VALUES($1)',[user.id]);
// Estrutura de recuperação entregue sem os cadastros iniciais: nenhuma exclusão necessária.
const estrutura=read('fase1.sql').split('INSERT INTO public.equipamentos')[0]+'COMMIT;\n';
await destino.exec(estrutura);await destino.exec(read('fase1-fechamento.sql'));
const recuperacao=gerarRecuperacao(data);await destino.exec(recuperacao);
const canon=x=>JSON.stringify(x,(_k,v)=>v&&typeof v==='object'&&!Array.isArray(v)?Object.fromEntries(Object.keys(v).sort().map(k=>[k,v[k]])):v);
for(const t of tabelas){const {rows}=await destino.query('SELECT to_jsonb(t) r FROM '+t+' t');assert.deepEqual(rows.map(x=>canon(x.r)).sort(),data[t].map(canon).sort());}
await assert.rejects(destino.exec(recuperacao));await destino.exec('ROLLBACK');
assert.equal((await destino.query('SELECT count(*)::int n FROM movimentacoes_estoque')).rows[0].n,2);
assert.throws(()=>gerarRecuperacao({...data,impressoes:undefined}));
fs.writeFileSync('fase1-estrutura-recuperacao.sql',estrutura);
console.log('OK: exportação restrita a master ativo; dez tabelas recuperadas com conteúdo igual, impressão estornada e dois movimentos; destino ocupado recusado sem perda.');
await db.close();await destino.close();
