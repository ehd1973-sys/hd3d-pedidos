'use strict';
// Registros FDM independentes da contagem de peças e logos.
const FDM={equipamentos:[],materiais:[],impressoes:[],movimentos:[],custos:[],edit:null,busy:false};
const fdmStatus={planejada:'Planejada',imprimindo:'Imprimindo',concluida:'Concluída',falha:'Falha',cancelada:'Cancelada',estornada:'Estornada',ativa:'Ativa',aguardando:'Aguardando ativação',manutencao:'Manutenção',inativa:'Inativa'};
const fdmMedido=(v,u='')=>v===null||v===undefined?'Não medido':`${Number(v).toLocaleString('pt-BR')}${u}`;
const fdmOpc=(arr,label)=>arr.map(x=>`<option value="${esc(x.id)}">${esc(label(x))}</option>`).join('');
for(const [v,t] of [['equipamentos','Impressoras'],['materiais','Materiais'],['impressoes','Impressões']]){
 const b=document.createElement('button');b.dataset.v=v;b.textContent=t;
 b.onclick=async()=>{document.querySelectorAll('nav button').forEach(x=>x.classList.toggle('on',x===b));document.querySelectorAll('main section').forEach(s=>s.classList.toggle('on',s.id==='v-'+v));await fdmCarregar();};
 document.querySelector('nav').append(b);
 const s=document.createElement('section');s.id='v-'+v;document.querySelector('main').append(s);
}
const fdmRefresh=atualizar;
atualizar=async function(){await fdmRefresh();if(['equipamentos','materiais','impressoes'].some(v=>$('#v-'+v).classList.contains('on')))await fdmCarregar();};
async function fdmCarregar(){
 if(!usuario||!perfil?.ativo)return;
 const v=['equipamentos','materiais','impressoes'].find(v=>$('#v-'+v).classList.contains('on'))||'impressoes';
 try{
  const r=await Promise.all([sb.from('equipamentos').select('*').order('codigo'),sb.from('materiais').select('*').order('tipo'),sb.from('impressoes').select('*').order('criado_em',{ascending:false}),sb.from('movimentacoes_estoque').select('*'),P('ver_financeiro')?sb.from('fdm_custos').select('*'):Promise.resolve({data:[]})]);
  [FDM.equipamentos,FDM.materiais,FDM.impressoes,FDM.movimentos,FDM.custos]=r.map(ok);
  fdmRender();
 }catch(e){$('#v-'+v).innerHTML=`<div class="card"><h3>Módulo de impressão indisponível</h3><p>Verifique se a migração da Fase 1 foi instalada neste ambiente.</p><p class="erro">${esc(traduz(e))}</p><button class="btn" onclick="fdmCarregar()">Tentar novamente</button></div>`;}
}
function fdmRender(){
 const edit=P('producao'),master=perfil?.master;
 $('#v-equipamentos').innerHTML='<h2>Impressoras</h2>'+(master?`<form class="card g g3" onsubmit="fdmNovoEquipamento(event)"><label>Código<input name="codigo" required maxlength="40" placeholder="IMP-004"></label><label>Nome<input name="nome" required maxlength="200"></label><button class="btn">Cadastrar aguardando ativação</button></form>`:'')+'<div class="kpis">'+FDM.equipamentos.map(e=>{
  const registros=FDM.impressoes.filter(i=>i.equipamento_id===e.id&&i.status!=='estornada');
  const medidos=registros.filter(i=>i.inicio_em&&i.fim_em),min=medidos.reduce((s,i)=>s+(Date.parse(i.fim_em)-Date.parse(i.inicio_em))/60000,0);
  return `<div class="card"><h3>${esc(e.codigo)} · ${esc(e.nome)}</h3><p>${esc(fdmStatus[e.status])}</p><p>Tempo registrado: <b>${medidos.length?fdmMedido(min/60,' h'):'Não medido'}</b></p><p class="muted">${medidos.length} registro(s) com início e fim; ${registros.length-medidos.length} sem duração medida.</p>${P('ver_financeiro')?`<p>Aquisição: ${FDM.custos.some(c=>c.id===e.id)?brl(FDM.custos.find(c=>c.id===e.id).valor):'Não informado'}</p>`:''}${master?`<label>Status<select onchange="fdmEquipamento('${e.id}',this.value)">${['ativa','aguardando','manutencao','inativa'].map(s=>`<option value="${s}" ${s===e.status?'selected':''}>${fdmStatus[s]}</option>`).join('')}</select></label>`:''}</div>`;
 }).join('')+'</div><p class="muted">Sem histórico fictício. Vida útil de 48 meses é cenário gerencial provisório; valor residual não definido.</p>';
 $('#v-materiais').innerHTML=`<h2>Materiais</h2>${master?`<form class="card g g3" onsubmit="fdmMaterial(event)"><label>Tipo<input name="tipo" required maxlength="100"></label><label>Fabricante<input name="fabricante" maxlength="150"></label><label>Cor<input name="cor" maxlength="100"></label><label>Estoque inicial medido (g)<input name="estoque" type="number" min="0" step="0.01" placeholder="Não medido"></label><button class="btn">Cadastrar material</button></form>`:''}<div class="kpis">${FDM.materiais.map(m=>{
  const delta=FDM.movimentos.filter(x=>x.material_id===m.id).reduce((s,x)=>s+(x.tipo==='consumo'?-1:1)*Number(x.quantidade_g),0);
  return `<div class="card"><h3>${esc(m.tipo)} · ${esc(m.cor||'Cor não informada')}</h3><p>${esc(m.fabricante||'Fabricante não informado')}</p><p>Estoque: <b>${m.estoque_inicial_g===null?'Não medido':fdmMedido(Number(m.estoque_inicial_g)+delta,' g')}</b></p><p>Movimentação registrada: ${fdmMedido(delta,' g')}</p>${P('ver_financeiro')?`<p>Referência/kg: ${FDM.custos.some(c=>c.id===m.id)?brl(FDM.custos.find(c=>c.id===m.id).valor):'Não informado'}</p>`:''}<p>${m.ativo?'Ativo':'Inativo'}</p></div>`;
 }).join('')}</div>`;
 $('#v-impressoes').innerHTML=`<h2>Impressões</h2><p class="muted">Estes registros não alteram as quantidades de peças e logos da tela Produção. Peça, purga e desperdício são medidos por trabalho, em gramas.</p>${edit?'<button class="btn ac" onclick="fdmAbrir()">+ Nova impressão</button>':''}<div id="fdmFormulario"></div><div style="overflow-x:auto;margin-top:14px"><table class="tbl resp"><thead><tr><th>Pedido</th><th>Impressora / material</th><th>Status</th><th>Duração</th><th>Peça / purga / perda</th><th>Ações</th></tr></thead><tbody>${FDM.impressoes.map(i=>{
  const p=pedidos.find(p=>p.id===i.pedido_id),e=FDM.equipamentos.find(e=>e.id===i.equipamento_id),m=FDM.materiais.find(m=>m.id===i.material_id);
  const dur=i.inicio_em&&i.fim_em?(Date.parse(i.fim_em)-Date.parse(i.inicio_em))/60000:null;
  const energia=P('ver_financeiro')&&e?.codigo==='IMP-001'&&m?.tipo==='PLA'&&dur!==null?`<br><small>Estimativa A1/PLA, 95 W: ${brl(dur/60*0.095*0.89)}. Referência provisória, não medida.</small>`:'';
  return `<tr><td data-l="Pedido">${p?esc(numPed(p.numero)+' · '+p.cliente):'Pedido não encontrado'}</td><td data-l="Impressora / material">${esc(e?.codigo||'—')} / ${esc(m?.tipo||'—')}</td><td data-l="Status">${esc(fdmStatus[i.status])}</td><td data-l="Duração">${fdmMedido(dur,' min')}${energia}</td><td data-l="Massas">${fdmMedido(i.peso_peca_g,' g')} / ${fdmMedido(i.purga_g,' g')} / ${fdmMedido(i.desperdicio_g,' g')}</td><td data-l="Ações">${edit?i.fechado_em?(i.status!=='estornada'?`<button class="btn sm lt" onclick="fdmEstornar('${i.id}')">Estornar consumo</button>`:''):`<button class="btn sm" onclick="fdmAbrir('${i.id}')">Editar / encerrar</button>`:''}</td></tr>`;
 }).join('')||'<tr><td colspan="6">Nenhuma impressão registrada.</td></tr>'}</tbody></table></div>`;
}
async function fdmEquipamento(id,status){try{if(!perfil?.master)return;ok(await sb.from('equipamentos').update({status}).eq('id',id));await fdmCarregar();}catch(e){falha(e,'atualizar impressora');await fdmCarregar();}}
async function fdmNovoEquipamento(e){e.preventDefault();if(!perfil?.master)return;const f=e.target,b=f.querySelector('button');b.disabled=true;try{ok(await sb.from('equipamentos').insert({codigo:f.elements.codigo.value.trim(),nome:f.elements.nome.value.trim(),status:'aguardando'}));await fdmCarregar();}catch(e){falha(e,'cadastrar impressora');}finally{b.disabled=false;}}
async function fdmMaterial(e){e.preventDefault();const f=e.target,b=f.querySelector('button');b.disabled=true;try{if(!perfil?.master)return;ok(await sb.from('materiais').insert({tipo:f.elements.tipo.value.trim(),fabricante:f.elements.fabricante.value.trim(),cor:f.elements.cor.value.trim(),estoque_inicial_g:f.elements.estoque.value===''?null:Number(f.elements.estoque.value)}));await fdmCarregar();}catch(e){falha(e,'cadastrar material');}finally{b.disabled=false;}}
function fdmLocal(v){if(!v)return '';const d=new Date(v);return new Date(d.getTime()-d.getTimezoneOffset()*60000).toISOString().slice(0,16);}
function fdmAbrir(id){
 if(!P('producao'))return;const i=FDM.impressoes.find(x=>x.id===id)||{};FDM.edit=id||null;
 const field=(key,label,type='number')=>`<label>${label}<input name="${key}" type="${type}" ${type==='number'?'min="0" step="0.01"':''} value="${esc(type==='datetime-local'?fdmLocal(i[key]):i[key]??'')}" placeholder="Não medido"></label>`;
 $('#fdmFormulario').innerHTML=`<form class="card" style="margin-top:14px" onsubmit="fdmSalvar(event)"><h3>${id?'Editar impressão':'Nova impressão'}</h3><div class="g g3"><label>Pedido<select name="pedido_id" required>${fdmOpc(pedidos.filter(p=>p.status!=='Cancelado'),p=>numPed(p.numero)+' · '+p.cliente)}</select></label><label>Impressora ativa<select name="equipamento_id" required>${fdmOpc(FDM.equipamentos.filter(e=>e.status==='ativa'||e.id===i.equipamento_id),e=>e.codigo+' · '+e.nome)}</select></label><label>Material<select name="material_id" required>${fdmOpc(FDM.materiais.filter(m=>m.ativo||m.id===i.material_id),m=>m.tipo+' · '+(m.cor||'Cor não informada'))}</select></label>${field('inicio_em','Início','datetime-local')}${field('fim_em','Término','datetime-local')}${field('tempo_fatiador_minutos','Tempo do fatiador (min)')}${field('peso_peca_g','Peso das peças (g)')}${field('purga_g','Purga medida (g)')}${field('desperdicio_g','Desperdício medido (g)')}<label>Motivo da falha<input name="falha_motivo" value="${esc(i.falha_motivo||'')}"></label><label>Observações<textarea name="observacoes">${esc(i.observacoes||'')}</textarea></label><label>Ação<select name="acao"><option value="planejada">Salvar como planejada</option><option value="imprimindo">Salvar em impressão</option><option value="concluida">Encerrar concluída</option><option value="falha">Encerrar com falha</option><option value="cancelada">Encerrar cancelada</option></select></label></div><p class="muted">Para encerrar, informe as três massas; use zero apenas quando medido. Um novo clique não desconta o estoque novamente. Horários seguem o fuso deste aparelho.</p><p id="fdmErro" class="erro" role="alert"></p><button class="btn ok">Salvar impressão</button> <button type="button" class="btn lt" onclick="document.querySelector('#fdmFormulario').innerHTML=''">Fechar</button></form>`;
 const f=$('#fdmFormulario form');for(const k of ['pedido_id','equipamento_id','material_id'])if(i[k])f.elements[k].value=i[k];f.elements.acao.value=i.status||'planejada';
}
async function fdmSalvar(e){
 e.preventDefault();if(FDM.busy||!P('producao'))return;const f=e.target,b=f.querySelector('button');const d={};
 try{
  const acao=f.elements.acao.value,fechar=['concluida','falha','cancelada'].includes(acao);
  for(const k of ['pedido_id','equipamento_id','material_id','falha_motivo','observacoes'])d[k]=f.elements[k].value;
  for(const k of ['peso_peca_g','purga_g','desperdicio_g','tempo_fatiador_minutos']){const v=f.elements[k].value;d[k]=v===''?null:Number(v);if(d[k]!==null&&(!Number.isFinite(d[k])||d[k]<0))throw Error('Informe medidas válidas e não negativas.');}
  for(const k of ['inicio_em','fim_em'])d[k]=f.elements[k].value?new Date(f.elements[k].value).toISOString():null;
  if(d.fim_em&&(!d.inicio_em||d.fim_em<d.inicio_em))throw Error('O término deve ser posterior ou igual ao início.');
  if(fechar&&['peso_peca_g','purga_g','desperdicio_g'].some(k=>d[k]===null))throw Error('Meça peça, purga e desperdício antes de encerrar.');
  if(['concluida','falha'].includes(acao)&&(!d.inicio_em||!d.fim_em))throw Error('Informe início e término.');
  if(acao==='falha'&&!d.falha_motivo.trim())throw Error('Informe o motivo da falha.');
  FDM.busy=true;b.disabled=true;d.status=fechar?'imprimindo':acao;
  if(FDM.edit)ok(await sb.from('impressoes').update(d).eq('id',FDM.edit));
  else{const r=ok(await sb.from('impressoes').insert(d).select('id').single());FDM.edit=r.id;}
  if(fechar)ok(await sb.rpc('fdm_encerrar',{p_id:FDM.edit,p_status:acao}));
  await fdmCarregar();toast('Impressão salva');
 }catch(e){$('#fdmErro').textContent=traduz(e);}finally{FDM.busy=false;b.disabled=false;}
}
async function fdmEstornar(id){if(!P('producao')||FDM.busy||!confirm('Estornar o consumo desta impressão? O registro e a movimentação original serão preservados.'))return;FDM.busy=true;try{ok(await sb.rpc('fdm_estornar',{p_id:id}));await fdmCarregar();toast('Consumo estornado');}catch(e){falha(e,'estornar impressão');}finally{FDM.busy=false;}}
