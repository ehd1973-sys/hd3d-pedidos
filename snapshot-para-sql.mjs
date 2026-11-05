// Converte uma cópia privada em SQL local. Não se conecta a nenhum serviço.
import fs from 'node:fs';
import {pathToFileURL} from 'node:url';
export const tabelas=['perfis','pedidos','despesas','pedido_custos','producao','equipamentos','materiais','fdm_custos','impressoes','movimentacoes_estoque'];
const tabelasBase=tabelas;
export const tabelasInsumos=['insumos','insumo_valores','insumo_operacoes','insumo_movimentos','insumo_movimento_valores','pedido_insumos','pedido_custos_insumos'];
export function linhasSQL(t,data){
 const literal="'"+JSON.stringify(data[t]).replaceAll("'","''")+"'::jsonb";
 return data.versao===2&&data.jsonb_em_texto&&['pedidos','despesas','insumo_operacoes'].includes(t)?`(SELECT coalesce(jsonb_agg(jsonb_set(x,'{dados}',(x->>'dados')::jsonb)),'[]'::jsonb) FROM jsonb_array_elements(${literal}) x)`:literal;
}
export function gerarRecuperacao(data){
 if(data?.app!=='HD3D-Fase1-snapshot'||![1,2].includes(data.versao))throw Error('Formato de cópia não reconhecido.');
 const tabelas=data.versao===2?[...tabelasBase,...tabelasInsumos]:tabelasBase;
 for(const t of tabelas)if(!Array.isArray(data[t]))throw Error('Tabela ausente: '+t);
 const quote=s=>"'"+s.replaceAll("'","''")+"'";
 const sql=['-- PRIVADO: recuperar somente em destino vazio com a estrutura da mesma versão.',
 '-- Os usuários de Auth com os UUIDs de perfis devem existir no destino.',
 'BEGIN;',"SET LOCAL standard_conforming_strings=on;",
 'LOCK TABLE '+tabelas.map(t=>'public.'+t).join(',')+' IN ACCESS EXCLUSIVE MODE;',
 'DO $$ BEGIN '+tabelas.map(t=>`IF EXISTS(SELECT FROM public.${t}) THEN RAISE EXCEPTION 'Destino não vazio: ${t}'; END IF;`).join(' ')+' END $$;'];
 // Somente no destino vazio e na mesma transação: preservar datas e estados históricos.
 sql.push('ALTER TABLE public.impressoes DISABLE TRIGGER fdm_validar;');
 if(data.versao===2)sql.push('ALTER TABLE public.materiais DISABLE TRIGGER ins_sync_material;');
 for(const t of tabelas)if(data[t].length)sql.push(`INSERT INTO public.${t} SELECT * FROM jsonb_populate_recordset(NULL::public.${t},${linhasSQL(t,data)});`);
 sql.push('ALTER TABLE public.impressoes ENABLE TRIGGER fdm_validar;');
 if(data.versao===2)sql.push('ALTER TABLE public.materiais ENABLE TRIGGER ins_sync_material;');
 sql.push("SELECT setval('public.pedidos_numero_seq',greatest(coalesce((SELECT max(numero) FROM public.pedidos),0)+1,1),false);",'COMMIT;');
 return sql.join('\n')+'\n';
}
if(process.argv[1]&&import.meta.url===pathToFileURL(process.argv[1]).href){
 const [entrada,saida]=process.argv.slice(2);
 if(!entrada||!saida)throw Error('Uso: node snapshot-para-sql.mjs copia.json recuperar.sql');
 const data=JSON.parse(fs.readFileSync(entrada,'utf8').replace(/^\uFEFF/,''));
 fs.writeFileSync(saida,gerarRecuperacao(data),{flag:'wx'});
 console.log('SQL privado gerado; nenhum banco foi alterado.');
}
