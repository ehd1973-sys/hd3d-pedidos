import {JSDOM} from 'jsdom';
import fs from 'node:fs';
import assert from 'node:assert/strict';
const html=fs.readFileSync('index.html','utf8'),dom=new JSDOM(html,{runScripts:'outside-only',url:'https://teste.invalid/'}),w=dom.window;
const inline=html.match(/<script>\s*([\s\S]*?)<\/script>/)[1].split('/* ---------- Início ---------- */')[0];
// Executa no mesmo escopo global para conservar os bindings originais do app.
const fixture=`
usuario={id:'u'};perfil={ativo:true,master:true};
pedidos=[{id:'p',numero:1,cliente:'Cliente <teste>',status:'Aprovado'}];
FDM.equipamentos=[{id:'e',codigo:'IMP-001',nome:'Bambu A1',status:'ativa'}];
FDM.materiais=[{id:'m',tipo:'PLA',cor:'',fabricante:'',ativo:true,estoque_inicial_g:null}];
FDM.impressoes=[];FDM.movimentos=[];FDM.custos=[];
fdmRender();fdmAbrir();
function fdmTestConfig(p,s){perfil=p;sb=s;}
`;
w.eval(inline+'\n'+fs.readFileSync('fdm.js','utf8')+'\n'+fixture);
assert.equal(w.document.querySelectorAll('nav button').length,8);
assert.match(w.document.querySelector('#v-equipamentos').textContent,/Não medido/);
assert.match(w.document.querySelector('#v-materiais').textContent,/Não medido/);
const f=w.document.querySelector('#fdmFormulario form');
assert.equal(f.elements.peso_peca_g.value,'');
assert.equal(f.elements.pedido_id.options[0].textContent,'#0001 · Cliente <teste>');
assert.equal(w.document.querySelector('#fdmFormulario teste'),null);
f.elements.acao.value='concluida';
await w.fdmSalvar({preventDefault(){},target:f});
assert.match(w.document.querySelector('#fdmErro').textContent,/Meça/);
// Cópia restrita e falha de rede sem produzir arquivo incompleto.
w.fdmTestConfig({ativo:true,master:false},{rpc:()=>{throw Error('Exportação indevida');}});
await w.fdmExportarSnapshot();
assert.equal(w.document.querySelector('#fdmBackupStatus').textContent,'');
w.fdmTestConfig({ativo:true,master:true},{rpc:async()=>({error:{message:'Failed to fetch'}})});
await w.fdmExportarSnapshot();
assert.match(w.document.querySelector('#fdmBackupStatus').textContent,/sem conexão/);
assert.equal(w.document.querySelector('#fdmExportar').disabled,false);
let downloaded=false;w.URL.createObjectURL=()=> 'blob:teste';w.URL.revokeObjectURL=()=>{};
w.HTMLAnchorElement.prototype.click=function(){downloaded=this.download.startsWith('HD3D-Fase1-')};
w.fdmTestConfig({ativo:true,master:true},{rpc:async()=>({data:{app:'HD3D-Fase1-snapshot',versao:1}})});
await w.fdmExportarSnapshot();assert.equal(downloaded,true);
console.log('Interface: navegação, cadastro, medidas ausentes, texto escapado e validação de encerramento: OK.');
console.log('Cópia FDM: leitor recusado, erro de rede tratado e download do administrador: OK.');
dom.window.close();
