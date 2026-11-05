import {PGlite} from '@electric-sql/pglite';
import fs from 'node:fs';
import assert from 'node:assert/strict';
process.on('uncaughtException',e=>{console.error(e.message);process.exit(1);});
const db=new PGlite();
const backup=JSON.parse(fs.readFileSync('../../outputs/HD3D_backup_2026-11-05/dados.json','utf8').replace(/^\uFEFF/,''));
await db.exec(fs.readFileSync('restore-fixture.sql','utf8'));
for(const p of backup.perfis) await db.query('insert into auth.users values($1)',[p.id]);
for(const t of ['perfis','pedidos','despesas','pedido_custos','producao']){
 for(const row of backup[t]){
  const keys=Object.keys(row);await db.query(`insert into public.${t}(${keys.map(x=>'"'+x+'"').join(',')}) values(${keys.map((_,i)=>'$'+(i+1)).join(',')})`,keys.map(k=>row[k]));
 }
 const {rows}=await db.query('select to_jsonb(t) as r from public.'+t+' t');
 const canonical=x=>JSON.stringify(x,(_k,v)=>v&&typeof v==='object'&&!Array.isArray(v)?Object.fromEntries(Object.keys(v).sort().map(k=>[k,v[k]])):v);
 assert.deepEqual(rows.map(x=>canonical(x.r)).sort(),backup[t].map(canonical).sort());
}
console.log('Restauração: cinco tabelas recuperadas; comparação de conteúdo concluída.');
await db.exec(fs.readFileSync('fase1.sql','utf8'));
await db.exec('grant usage on schema public,auth to authenticated; grant select on public.pedidos,public.perfis to authenticated;');
const uid=backup.perfis[0].id,pedido=backup.pedidos[0].id;
await db.query("select set_config('request.jwt.claim.sub',$1,false)",[uid]);
await db.exec('set role authenticated');
const eq='00000000-0000-4000-8000-000000000001',mat='00000000-0000-4000-8000-000000000011';
const expectError=async(sql,args=[])=>{await assert.rejects(db.query(sql,args));};
await expectError('insert into impressoes(pedido_id,equipamento_id,material_id,peso_peca_g) values($1,$2,$3,-1)',[pedido,eq,mat]);
await expectError('insert into impressoes(pedido_id,equipamento_id,material_id) values($1,$2,$3)',[pedido,'00000000-0000-4000-8000-000000000002',mat]);
const {rows:[imp]}=await db.query("insert into impressoes(pedido_id,equipamento_id,material_id,inicio_em,fim_em,peso_peca_g,purga_g,desperdicio_g) values($1,$2,$3,'2026-11-05 12:00Z','2026-11-05 13:00Z',10,2,0) returning id",[pedido,eq,mat]);
await db.query("select fdm_encerrar($1,'concluida')",[imp.id]);
await db.query("select fdm_encerrar($1,'concluida')",[imp.id]);
assert.equal((await db.query('select count(*)::int as n from movimentacoes_estoque')).rows[0].n,1);
await db.query('select fdm_estornar($1)',[imp.id]);await db.query('select fdm_estornar($1)',[imp.id]);
assert.equal((await db.query('select sum(case when tipo=\'consumo\' then -quantidade_g else quantidade_g end)::float as saldo from movimentacoes_estoque')).rows[0].saldo,0);
await expectError('insert into movimentacoes_estoque(material_id,impressao_id,tipo,quantidade_g,usuario_id) values($1,$2,\'consumo\',3,$3)',[mat,imp.id,uid]);
await expectError('update impressoes set fechado_em=null where id=$1',[imp.id]);
const op='11111111-1111-4111-8111-111111111111';
await db.exec('reset role');await db.query('insert into auth.users values($1)',[op]);await db.query("insert into perfis(id,email) values($1,'operador@teste.invalid')",[op]);
await db.query("select set_config('request.jwt.claim.sub',$1,false)",[op]);await db.exec('set role authenticated');
assert.equal((await db.query('select * from fdm_custos')).rows.length,0);
await expectError('select fdm_estornar($1)',[imp.id]);
await expectError('insert into impressoes(pedido_id,equipamento_id,material_id) values($1,$2,$3)',[pedido,eq,mat]);
await db.exec('reset role');
assert.equal((await db.query('select count(*)::int n from producao')).rows[0].n,backup.producao.length);
console.log('Migração: inclusão, validações, permissões, custos protegidos, encerramento repetido, estorno repetido e produção preservada: OK.');
await db.close();
