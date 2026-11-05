-- Evolução aditiva: estoque integrado e custo de insumos. Aplicar primeiro em homologação.
BEGIN;
CREATE TABLE public.insumos (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), material_id uuid UNIQUE REFERENCES public.materiais(id),
 codigo text NOT NULL UNIQUE CHECK(length(trim(codigo))>0), nome text NOT NULL CHECK(length(trim(nome))>0),
 categoria text NOT NULL CHECK(categoria IN ('filamento','componente','conjunto','embalagem','outro')),
 unidade text NOT NULL CHECK(unidade IN ('g','un','m','ml')), ativo boolean NOT NULL DEFAULT true,
 saldo numeric CHECK(saldo>=0 AND saldo<1e12), minimo numeric NOT NULL DEFAULT 0 CHECK(minimo>=0 AND minimo<1e12),
 criado_em timestamptz NOT NULL DEFAULT now(), CHECK((categoria='filamento')=(material_id IS NOT NULL)),
 CHECK(categoria<>'filamento' OR unidade='g'), CHECK(unidade<>'un' OR saldo=trunc(saldo))
);
CREATE TABLE public.insumo_valores (
 insumo_id uuid PRIMARY KEY REFERENCES public.insumos(id),
 custo_medio numeric CHECK(custo_medio>=0 AND custo_medio<1e12),
 referencia numeric CHECK(referencia>=0 AND referencia<1e12)
);
CREATE TABLE public.insumo_operacoes (
 id uuid PRIMARY KEY, autor uuid REFERENCES public.perfis(id), tipo text NOT NULL, pedido_id uuid REFERENCES public.pedidos(id),
 dados jsonb NOT NULL, criado_em timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.insumo_movimentos (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), operacao_id uuid NOT NULL REFERENCES public.insumo_operacoes(id),
 insumo_id uuid NOT NULL REFERENCES public.insumos(id), pedido_id uuid REFERENCES public.pedidos(id) ON DELETE RESTRICT,
 impressao_id uuid REFERENCES public.impressoes(id),
 tipo text NOT NULL CHECK(tipo IN ('migracao','contagem','entrada','consumo','estorno','retorno_legado')),
 quantidade numeric NOT NULL CHECK(abs(quantidade)<1e12), saldo_antes numeric, saldo_depois numeric,
 estorno_de uuid UNIQUE REFERENCES public.insumo_movimentos(id), observacoes text NOT NULL DEFAULT '',
 autor uuid REFERENCES public.perfis(id), criado_em timestamptz NOT NULL DEFAULT now(),
 UNIQUE(operacao_id,insumo_id,tipo), CHECK(saldo_depois IS NULL OR saldo_depois>=0)
);
CREATE UNIQUE INDEX insumo_impressao_tipo ON public.insumo_movimentos(impressao_id,tipo) WHERE impressao_id IS NOT NULL;
CREATE INDEX insumo_mov_pedido ON public.insumo_movimentos(pedido_id,insumo_id);
CREATE TABLE public.insumo_movimento_valores (
 movimento_id uuid PRIMARY KEY REFERENCES public.insumo_movimentos(id), custo_unitario numeric,
 custo_total numeric, custo_medio_antes numeric, custo_medio_depois numeric
);
CREATE TABLE public.pedido_insumos (
 pedido_id uuid NOT NULL REFERENCES public.pedidos(id) ON DELETE RESTRICT,
 insumo_id uuid NOT NULL REFERENCES public.insumos(id),
 quantidade_por_peca numeric NOT NULL CHECK(quantidade_por_peca>0 AND quantidade_por_peca<1e9),
 PRIMARY KEY(pedido_id,insumo_id)
);
CREATE TABLE public.pedido_custos_insumos (
 pedido_id uuid PRIMARY KEY REFERENCES public.pedidos(id) ON DELETE RESTRICT,
 extras_planejados numeric CHECK(extras_planejados>=0 AND extras_planejados<1e12),
 extras_reais numeric CHECK(extras_reais>=0 AND extras_reais<1e12), observacoes text NOT NULL DEFAULT '',
 custo_unit_aplicado numeric, aplicado_em timestamptz
);
ALTER TABLE public.insumos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.insumo_valores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.insumo_operacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.insumo_movimentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.insumo_movimento_valores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedido_insumos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedido_custos_insumos ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.insumos,public.insumo_valores,public.insumo_operacoes,public.insumo_movimentos,public.insumo_movimento_valores,public.pedido_insumos,public.pedido_custos_insumos FROM PUBLIC,anon,authenticated;
CREATE POLICY insumos_ler ON public.insumos FOR SELECT TO authenticated USING(public.tem('ativo'));
CREATE POLICY insumo_movimentos_ler ON public.insumo_movimentos FOR SELECT TO authenticated USING(public.tem('ativo'));
CREATE POLICY pedido_insumos_ler ON public.pedido_insumos FOR SELECT TO authenticated USING(public.tem('ativo'));
CREATE POLICY insumo_valores_ler ON public.insumo_valores FOR SELECT TO authenticated USING(public.tem('financeiro'));
CREATE POLICY insumo_mov_valores_ler ON public.insumo_movimento_valores FOR SELECT TO authenticated USING(public.tem('financeiro'));
CREATE POLICY pedido_custos_insumos_ler ON public.pedido_custos_insumos FOR SELECT TO authenticated USING(public.tem('financeiro'));
GRANT SELECT ON public.insumos,public.insumo_movimentos,public.pedido_insumos,public.insumo_valores,public.insumo_movimento_valores,public.pedido_custos_insumos TO authenticated;

-- Saldo existente é preservado quando conhecido; valor de referência não vira custo real.
INSERT INTO public.insumos(id,material_id,codigo,nome,categoria,unidade,ativo,saldo)
 SELECT m.id,m.id,'MAT-'||m.id::text,concat_ws(' · ',m.tipo,nullif(m.fabricante,''),nullif(m.cor,'')),
 'filamento','g',m.ativo,CASE WHEN m.estoque_inicial_g IS NOT NULL AND m.estoque_inicial_g+coalesce(x.delta,0)>=0
 THEN m.estoque_inicial_g+coalesce(x.delta,0) END
 FROM public.materiais m LEFT JOIN LATERAL (SELECT sum(CASE WHEN tipo='consumo' THEN -quantidade_g ELSE quantidade_g END) delta FROM public.movimentacoes_estoque WHERE material_id=m.id)x ON true;
INSERT INTO public.insumo_valores(insumo_id,referencia)
 SELECT i.id,c.valor/1000 FROM public.insumos i LEFT JOIN public.fdm_custos c ON c.id=i.material_id AND c.categoria='material';
INSERT INTO public.insumo_operacoes(id,tipo,dados) VALUES('00000000-0000-4000-8000-000000000101','migracao','{}');
INSERT INTO public.insumo_movimentos(operacao_id,insumo_id,tipo,quantidade,saldo_depois,observacoes)
 SELECT '00000000-0000-4000-8000-000000000101',id,'migracao',saldo,saldo,'Saldo conhecido migrado da Fase 1; custo a conferir' FROM public.insumos WHERE saldo IS NOT NULL;
INSERT INTO public.insumos(codigo,nome,categoria,unidade) VALUES
 ('ARGOLA','Argola de chaveiro','componente','un'),('CORRENTINHA','Correntinha de chaveiro','componente','un'),
 ('CONJUNTO-CHAVEIRO','Conjunto argola + correntinha','conjunto','un');
INSERT INTO public.insumo_valores(insumo_id) SELECT id FROM public.insumos ON CONFLICT DO NOTHING;

CREATE FUNCTION public._ins_sync_material() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
BEGIN
 INSERT INTO public.insumos(id,material_id,codigo,nome,categoria,unidade,ativo)
 VALUES(NEW.id,NEW.id,'MAT-'||NEW.id::text,concat_ws(' · ',NEW.tipo,nullif(NEW.fabricante,''),nullif(NEW.cor,'')),'filamento','g',NEW.ativo);
 INSERT INTO public.insumo_valores(insumo_id) VALUES(NEW.id); RETURN NEW;
END $$;
CREATE TRIGGER ins_sync_material AFTER INSERT ON public.materiais FOR EACH ROW EXECUTE FUNCTION public._ins_sync_material();

CREATE FUNCTION public._ins_operacao(p_id uuid,p_tipo text,p_pedido uuid,p_dados jsonb) RETURNS boolean LANGUAGE plpgsql SET search_path=public,pg_temp AS $$
DECLARE r public.insumo_operacoes; BEGIN
 IF p_id IS NULL THEN RAISE EXCEPTION 'Identificador obrigatório'; END IF;
 INSERT INTO public.insumo_operacoes(id,autor,tipo,pedido_id,dados) VALUES(p_id,auth.uid(),p_tipo,p_pedido,p_dados) ON CONFLICT DO NOTHING;
 IF FOUND THEN RETURN true; END IF;
 SELECT * INTO r FROM public.insumo_operacoes WHERE id=p_id FOR UPDATE;
 IF r.autor IS DISTINCT FROM auth.uid() OR r.tipo<>p_tipo OR r.pedido_id IS DISTINCT FROM p_pedido OR r.dados IS DISTINCT FROM p_dados THEN RAISE EXCEPTION 'Identificador reutilizado com dados diferentes; confira o histórico'; END IF;
 RETURN false;
END $$;
CREATE FUNCTION public.ins_cadastrar(p_codigo text,p_nome text,p_categoria text,p_unidade text) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE v uuid; BEGIN
 IF NOT public.tem('master') THEN RAISE EXCEPTION 'Apenas master pode cadastrar insumos'; END IF;
 IF length(trim(p_nome))=0 OR length(trim(p_codigo))=0 THEN RAISE EXCEPTION 'Informe código e nome'; END IF;
 IF p_categoria='filamento' THEN
  IF p_unidade<>'g' THEN RAISE EXCEPTION 'Filamento é controlado em gramas'; END IF;
  INSERT INTO public.materiais(tipo) VALUES(trim(p_nome)) RETURNING id INTO v;
  UPDATE public.insumos SET codigo=trim(p_codigo) WHERE id=v;
 ELSE
  INSERT INTO public.insumos(codigo,nome,categoria,unidade) VALUES(trim(p_codigo),trim(p_nome),p_categoria,p_unidade) RETURNING id INTO v;
  INSERT INTO public.insumo_valores(insumo_id) VALUES(v);
 END IF; RETURN v;
END $$;
CREATE FUNCTION public.ins_configurar(p_id uuid,p_minimo numeric,p_ativo boolean,p_referencia numeric) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
BEGIN
 IF NOT public.tem('master') THEN RAISE EXCEPTION 'Apenas master pode configurar insumos'; END IF;
 -- Mesma ordem de bloqueio usada pelo encerramento FDM: material, depois insumo.
 PERFORM 1 FROM public.materiais WHERE id=(SELECT material_id FROM public.insumos WHERE id=p_id) FOR UPDATE;
 UPDATE public.insumos SET minimo=p_minimo,ativo=p_ativo WHERE id=p_id;
 IF NOT FOUND THEN RAISE EXCEPTION 'Insumo não encontrado'; END IF;
 UPDATE public.insumo_valores SET referencia=p_referencia WHERE insumo_id=p_id;
 UPDATE public.materiais SET ativo=p_ativo WHERE id=(SELECT material_id FROM public.insumos WHERE id=p_id);
 INSERT INTO public.insumo_operacoes(id,autor,tipo,dados) VALUES(gen_random_uuid(),auth.uid(),'configuracao',jsonb_build_object('insumo',p_id,'minimo',p_minimo,'ativo',p_ativo,'referencia',p_referencia));
END $$;
CREATE FUNCTION public.ins_estoque(p_operacao uuid,p_insumo uuid,p_tipo text,p_quantidade numeric,p_valor numeric,p_observacoes text) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE i public.insumos; anterior numeric; novo numeric; delta numeric; mid uuid; unitario numeric;
BEGIN
 IF p_tipo='contagem' THEN
  IF NOT public.tem('master') THEN RAISE EXCEPTION 'Apenas master pode fazer contagem'; END IF;
 ELSIF p_tipo='entrada' THEN
  IF NOT public.tem('despesas') THEN RAISE EXCEPTION 'Sem permissão para registrar compra'; END IF;
 ELSE RAISE EXCEPTION 'Tipo inválido'; END IF;
 IF p_quantidade IS NULL OR p_quantidade<0 OR p_quantidade>=1e12 OR (p_tipo='entrada' AND p_quantidade=0) OR p_valor IS NULL OR p_valor<0 OR p_valor>=1e12 THEN RAISE EXCEPTION 'Informe quantidade e valor válidos; zero somente quando informado'; END IF;
 IF p_observacoes IS NULL OR length(trim(p_observacoes))=0 THEN RAISE EXCEPTION 'Informe documento ou motivo do lançamento'; END IF;
 IF NOT public._ins_operacao(p_operacao,p_tipo,NULL,jsonb_build_object('insumo',p_insumo,'quantidade',p_quantidade,'valor',p_valor,'observacoes',p_observacoes)) THEN RETURN; END IF;
 SELECT * INTO i FROM public.insumos WHERE id=p_insumo FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Insumo não encontrado'; END IF;
 IF i.unidade='un' AND p_quantidade<>trunc(p_quantidade) THEN RAISE EXCEPTION 'Unidades exigem quantidade inteira'; END IF;
 SELECT custo_medio INTO anterior FROM public.insumo_valores WHERE insumo_id=i.id;
 IF p_tipo='contagem' THEN novo=p_valor; delta=p_quantidade-coalesce(i.saldo,0); unitario=p_valor;
 ELSE
  IF i.saldo IS NULL THEN RAISE EXCEPTION 'Faça a contagem inicial antes de registrar compras'; END IF;
  IF i.saldo>0 AND anterior IS NULL THEN RAISE EXCEPTION 'Informe o custo atribuído ao estoque na contagem'; END IF;
  unitario=p_valor/p_quantidade;
  novo=(coalesce(i.saldo*anterior,0)+p_valor)/(i.saldo+p_quantidade); delta=p_quantidade;
 END IF;
 UPDATE public.insumos SET saldo=CASE WHEN p_tipo='contagem' THEN p_quantidade ELSE saldo+p_quantidade END WHERE id=i.id;
 UPDATE public.insumo_valores SET custo_medio=novo WHERE insumo_id=i.id;
 INSERT INTO public.insumo_movimentos(operacao_id,insumo_id,tipo,quantidade,saldo_antes,saldo_depois,observacoes,autor)
 VALUES(p_operacao,i.id,p_tipo,delta,i.saldo,CASE WHEN p_tipo='contagem' THEN p_quantidade ELSE i.saldo+p_quantidade END,coalesce(p_observacoes,''),auth.uid()) RETURNING id INTO mid;
 INSERT INTO public.insumo_movimento_valores VALUES(mid,unitario,delta*unitario,anterior,novo);
END $$;
CREATE FUNCTION public._ins_debitar(p_operacao uuid,p_insumo uuid,p_pedido uuid,p_impressao uuid,p_quantidade numeric,p_obs text) RETURNS void LANGUAGE plpgsql SET search_path=public,pg_temp AS $$
DECLARE i public.insumos; custo numeric; mid uuid; BEGIN
 IF p_quantidade IS NULL OR p_quantidade<=0 OR p_quantidade>=1e12 THEN RAISE EXCEPTION 'Consumo deve ser positivo'; END IF;
 SELECT * INTO i FROM public.insumos WHERE id=p_insumo FOR UPDATE;
 IF NOT FOUND OR NOT i.ativo THEN RAISE EXCEPTION 'Insumo inexistente ou inativo'; END IF;
 IF i.unidade='un' AND p_quantidade<>trunc(p_quantidade) THEN RAISE EXCEPTION 'Unidades exigem quantidade inteira'; END IF;
 IF i.saldo IS NULL THEN RAISE EXCEPTION 'Estoque não contado: %',i.nome; END IF;
 IF i.saldo<p_quantidade THEN RAISE EXCEPTION 'Estoque insuficiente: %; disponível % %',i.nome,i.saldo,i.unidade; END IF;
 SELECT custo_medio INTO custo FROM public.insumo_valores WHERE insumo_id=i.id;
 IF custo IS NULL THEN RAISE EXCEPTION 'Custo do estoque pendente: solicite a conferência financeira'; END IF;
 UPDATE public.insumos SET saldo=saldo-p_quantidade WHERE id=i.id;
 INSERT INTO public.insumo_movimentos(operacao_id,insumo_id,pedido_id,impressao_id,tipo,quantidade,saldo_antes,saldo_depois,observacoes,autor)
 VALUES(p_operacao,i.id,p_pedido,p_impressao,'consumo',-p_quantidade,i.saldo,i.saldo-p_quantidade,coalesce(p_obs,''),auth.uid()) RETURNING id INTO mid;
 INSERT INTO public.insumo_movimento_valores VALUES(mid,custo,-p_quantidade*custo,custo,custo);
END $$;
CREATE FUNCTION public.ins_consumir(p_operacao uuid,p_pedido uuid,p_itens jsonb,p_observacoes text) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE item record; BEGIN
 IF NOT public.tem('producao') THEN RAISE EXCEPTION 'Sem permissão de produção'; END IF;
 PERFORM 1 FROM public.pedidos WHERE id=p_pedido AND dados->>'status'<>'Cancelado' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Pedido indisponível ou cancelado'; END IF;
 IF p_itens IS NULL OR jsonb_typeof(p_itens)<>'array' OR jsonb_array_length(p_itens)=0 THEN RAISE EXCEPTION 'Informe os insumos consumidos'; END IF;
 IF EXISTS(SELECT FROM jsonb_to_recordset(p_itens) AS x(insumo_id uuid,quantidade numeric) WHERE insumo_id IS NULL OR quantidade IS NULL OR quantidade<=0 OR quantidade>=1e12) THEN RAISE EXCEPTION 'Cada consumo deve ter quantidade positiva'; END IF;
 IF NOT public._ins_operacao(p_operacao,'consumo',p_pedido,jsonb_build_object('itens',p_itens,'observacoes',p_observacoes)) THEN RETURN; END IF;
 FOR item IN SELECT insumo_id,sum(quantidade) quantidade FROM jsonb_to_recordset(p_itens) AS x(insumo_id uuid,quantidade numeric) GROUP BY insumo_id ORDER BY insumo_id LOOP
  PERFORM public._ins_debitar(p_operacao,item.insumo_id,p_pedido,NULL,item.quantidade,p_observacoes);
 END LOOP;
END $$;
CREATE FUNCTION public._ins_devolver(p_operacao uuid,p_movimento uuid) RETURNS void LANGUAGE plpgsql SET search_path=public,pg_temp AS $$
DECLARE m public.insumo_movimentos; i public.insumos; original numeric; atual numeric; novo numeric; mid uuid; q numeric; BEGIN
 SELECT * INTO m FROM public.insumo_movimentos WHERE id=p_movimento FOR UPDATE;
 IF NOT FOUND OR m.tipo<>'consumo' THEN RAISE EXCEPTION 'Consumo não encontrado'; END IF;
 IF EXISTS(SELECT FROM public.insumo_movimentos WHERE estorno_de=m.id) THEN RETURN; END IF;
 SELECT * INTO i FROM public.insumos WHERE id=m.insumo_id FOR UPDATE;
 SELECT custo_unitario INTO original FROM public.insumo_movimento_valores WHERE movimento_id=m.id;
 SELECT custo_medio INTO atual FROM public.insumo_valores WHERE insumo_id=i.id;
 q=-m.quantidade;
 novo=CASE WHEN i.saldo IS NULL OR original IS NULL OR (i.saldo>0 AND atual IS NULL) THEN NULL ELSE (coalesce(i.saldo*atual,0)+q*original)/(i.saldo+q) END;
 UPDATE public.insumos SET saldo=saldo+q WHERE id=i.id;
 UPDATE public.insumo_valores SET custo_medio=novo WHERE insumo_id=i.id;
 INSERT INTO public.insumo_movimentos(operacao_id,insumo_id,pedido_id,impressao_id,tipo,quantidade,saldo_antes,saldo_depois,estorno_de,observacoes,autor)
 VALUES(p_operacao,i.id,m.pedido_id,m.impressao_id,'estorno',q,i.saldo,i.saldo+q,m.id,'Compensação do consumo original',auth.uid()) RETURNING id INTO mid;
 INSERT INTO public.insumo_movimento_valores VALUES(mid,original,q*original,atual,novo);
END $$;
CREATE FUNCTION public.ins_estornar(p_operacao uuid) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE op public.insumo_operacoes; m record; eid uuid; BEGIN
 IF NOT public.tem('producao') THEN RAISE EXCEPTION 'Sem permissão de produção'; END IF;
 SELECT * INTO op FROM public.insumo_operacoes WHERE id=p_operacao FOR UPDATE;
 IF NOT FOUND OR op.tipo<>'consumo' THEN RAISE EXCEPTION 'Operação de consumo não encontrada'; END IF;
 IF EXISTS(SELECT FROM public.insumo_movimentos WHERE operacao_id=op.id AND impressao_id IS NOT NULL) THEN RAISE EXCEPTION 'Use o estorno na tela Impressões'; END IF;
 IF NOT EXISTS(SELECT FROM public.insumo_movimentos origem WHERE origem.operacao_id=op.id AND origem.tipo='consumo' AND NOT EXISTS(SELECT FROM public.insumo_movimentos e WHERE e.estorno_de=origem.id)) THEN RETURN; END IF;
 eid=gen_random_uuid(); INSERT INTO public.insumo_operacoes(id,autor,tipo,pedido_id,dados) VALUES(eid,auth.uid(),'estorno',op.pedido_id,jsonb_build_object('origem',op.id));
 FOR m IN SELECT id FROM public.insumo_movimentos WHERE operacao_id=op.id AND tipo='consumo' ORDER BY insumo_id LOOP PERFORM public._ins_devolver(eid,m.id); END LOOP;
END $$;
CREATE FUNCTION public.ins_planejar(p_pedido uuid,p_itens jsonb) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
BEGIN
 IF NOT (public.tem('editar') OR public.tem('producao')) THEN RAISE EXCEPTION 'Sem permissão de planejamento'; END IF;
 PERFORM 1 FROM public.pedidos WHERE id=p_pedido FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Pedido não encontrado'; END IF;
 IF p_itens IS NULL OR jsonb_typeof(p_itens)<>'array' THEN RAISE EXCEPTION 'Composição inválida'; END IF;
 INSERT INTO public.insumo_operacoes(id,autor,tipo,pedido_id,dados) VALUES(gen_random_uuid(),auth.uid(),'planejamento',p_pedido,jsonb_build_object('antes',(SELECT coalesce(jsonb_agg(to_jsonb(t)),'[]') FROM public.pedido_insumos t WHERE pedido_id=p_pedido),'depois',p_itens));
 DELETE FROM public.pedido_insumos WHERE pedido_id=p_pedido;
 INSERT INTO public.pedido_insumos SELECT p_pedido,insumo_id,quantidade_por_peca FROM jsonb_to_recordset(p_itens) AS x(insumo_id uuid,quantidade_por_peca numeric);
END $$;
CREATE FUNCTION public._ins_custos(p_pedido uuid) RETURNS jsonb LANGUAGE plpgsql STABLE SET search_path=public,pg_temp AS $$
DECLARE q numeric; parcial numeric; faltam int; itens int; real_ins numeric; movs int; legados int; extra public.pedido_custos_insumos; BEGIN
 SELECT coalesce(nullif(dados->>'qtde','')::numeric,0) INTO q FROM public.pedidos WHERE id=p_pedido;
 SELECT count(*),count(*) FILTER(WHERE coalesce(v.custo_medio,v.referencia) IS NULL),coalesce(sum(p.quantidade_por_peca*q*coalesce(v.custo_medio,v.referencia)),0)
 INTO itens,faltam,parcial FROM public.pedido_insumos p LEFT JOIN public.insumo_valores v ON v.insumo_id=p.insumo_id WHERE p.pedido_id=p_pedido;
 SELECT count(*),coalesce(-sum(v.custo_total),0) INTO movs,real_ins FROM public.insumo_movimentos m JOIN public.insumo_movimento_valores v ON v.movimento_id=m.id WHERE m.pedido_id=p_pedido AND m.tipo IN ('consumo','estorno');
 SELECT count(*) INTO legados FROM public.impressoes i WHERE i.pedido_id=p_pedido AND i.fechado_em IS NOT NULL AND i.status<>'estornada' AND NOT EXISTS(SELECT FROM public.insumo_operacoes op WHERE op.tipo='consumo_fdm' AND op.dados->>'impressao'=i.id::text);
 SELECT * INTO extra FROM public.pedido_custos_insumos WHERE pedido_id=p_pedido;
 RETURN jsonb_build_object('pedido_id',p_pedido,'quantidade',q,'itens',itens,'faltam_precos',faltam,'planejado_insumos',CASE WHEN faltam=0 AND itens>0 THEN parcial END,'planejado_parcial',parcial,
 'previsto_total',CASE WHEN faltam=0 AND itens>0 AND extra.extras_planejados IS NOT NULL THEN parcial+extra.extras_planejados END,
 'extras_planejados',extra.extras_planejados,'extras_reais',extra.extras_reais,'observacoes',extra.observacoes,'consumido_insumos',real_ins,'movimentos',movs,'legados_sem_custo',legados,
 'real_total',CASE WHEN movs>0 AND legados=0 AND extra.extras_reais IS NOT NULL THEN real_ins+extra.extras_reais END,'custo_unit_aplicado',extra.custo_unit_aplicado,'aplicado_em',extra.aplicado_em);
END $$;
CREATE FUNCTION public.ins_custo_pedido(p_pedido uuid,p_extras_planejados numeric,p_extras_reais numeric,p_observacoes text,p_aplicar boolean) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE c jsonb; unitario numeric; BEGIN
 IF NOT (public.tem('financeiro') AND public.tem('editar')) THEN RAISE EXCEPTION 'Exige financeiro e edição'; END IF;
 PERFORM 1 FROM public.pedidos WHERE id=p_pedido FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Pedido não encontrado'; END IF;
 INSERT INTO public.pedido_custos_insumos(pedido_id,extras_planejados,extras_reais,observacoes) VALUES(p_pedido,p_extras_planejados,p_extras_reais,coalesce(p_observacoes,'')) ON CONFLICT(pedido_id) DO UPDATE SET extras_planejados=excluded.extras_planejados,extras_reais=excluded.extras_reais,observacoes=excluded.observacoes;
 c=public._ins_custos(p_pedido);
 IF p_aplicar THEN
  IF (c->>'previsto_total') IS NULL OR (c->>'quantidade')::numeric<=0 THEN RAISE EXCEPTION 'Complete composição, preços e outros custos planejados (zero quando informado)'; END IF;
  unitario=round((c->>'previsto_total')::numeric/(c->>'quantidade')::numeric,6);
  INSERT INTO public.pedido_custos(pedido_id,custo_unit) VALUES(p_pedido,unitario) ON CONFLICT(pedido_id) DO UPDATE SET custo_unit=excluded.custo_unit;
  UPDATE public.pedido_custos_insumos SET custo_unit_aplicado=unitario,aplicado_em=now() WHERE pedido_id=p_pedido;
 END IF;
 INSERT INTO public.insumo_operacoes(id,autor,tipo,pedido_id,dados) VALUES(gen_random_uuid(),auth.uid(),'custos_pedido',p_pedido,jsonb_build_object('extras_planejados',p_extras_planejados,'extras_reais',p_extras_reais,'observacoes',p_observacoes,'custo_unit_aplicado',unitario));
END $$;

-- Mesmo encerramento FDM, com baixa integrada e reversão transacional.
ALTER FUNCTION public.fdm_encerrar(uuid,text) RENAME TO fdm_encerrar_fase1;
ALTER FUNCTION public.fdm_estornar(uuid) RENAME TO fdm_estornar_fase1;
CREATE FUNCTION public.fdm_encerrar(p_id uuid,p_status text) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE i public.impressoes; q numeric; op uuid; BEGIN
 IF NOT public.tem('producao') THEN RAISE EXCEPTION 'Sem permissão de produção'; END IF;
 SELECT * INTO i FROM public.impressoes WHERE id=p_id FOR UPDATE;
 PERFORM public.fdm_encerrar_fase1(p_id,p_status);
 IF i.fechado_em IS NOT NULL THEN RETURN; END IF;
 q=i.peso_peca_g+i.purga_g+i.desperdicio_g;
 op=gen_random_uuid(); INSERT INTO public.insumo_operacoes(id,autor,tipo,pedido_id,dados) VALUES(op,auth.uid(),'consumo_fdm',i.pedido_id,jsonb_build_object('impressao',i.id));
 IF q>0 THEN
  PERFORM public._ins_debitar(op,i.material_id,i.pedido_id,i.id,q,'Consumo automático da impressão');
 END IF;
END $$;
CREATE FUNCTION public.fdm_estornar(p_id uuid) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE i public.impressoes; m uuid; op uuid; q numeric; saldo_ant numeric; BEGIN
 IF NOT public.tem('producao') THEN RAISE EXCEPTION 'Sem permissão de produção'; END IF;
 SELECT * INTO i FROM public.impressoes WHERE id=p_id FOR UPDATE;
 PERFORM public.fdm_estornar_fase1(p_id);
 IF i.status='estornada' THEN RETURN; END IF;
 SELECT id INTO m FROM public.insumo_movimentos WHERE impressao_id=i.id AND tipo='consumo';
 IF m IS NOT NULL THEN
  op=gen_random_uuid(); INSERT INTO public.insumo_operacoes(id,autor,tipo,pedido_id,dados) VALUES(op,auth.uid(),'estorno_fdm',i.pedido_id,jsonb_build_object('impressao',i.id));
  PERFORM public._ins_devolver(op,m);
 ELSE
  -- Histórico anterior não tem custo recuperável: exige recontagem, sem inventar valor.
  SELECT quantidade_g INTO q FROM public.movimentacoes_estoque WHERE impressao_id=i.id AND tipo='consumo';
  IF q>0 THEN
   SELECT saldo INTO saldo_ant FROM public.insumos WHERE id=i.material_id FOR UPDATE;
   op=gen_random_uuid(); INSERT INTO public.insumo_operacoes(id,autor,tipo,pedido_id,dados) VALUES(op,auth.uid(),'retorno_legado',i.pedido_id,jsonb_build_object('impressao',i.id));
   UPDATE public.insumos SET saldo=NULL WHERE id=i.material_id; UPDATE public.insumo_valores SET custo_medio=NULL WHERE insumo_id=i.material_id;
   INSERT INTO public.insumo_movimentos(operacao_id,insumo_id,pedido_id,impressao_id,tipo,quantidade,saldo_antes,observacoes,autor) VALUES(op,i.material_id,i.pedido_id,i.id,'retorno_legado',q,saldo_ant,'Estorno de impressão anterior à integração: recontar estoque e conferir custo',auth.uid());
  END IF;
 END IF;
END $$;

CREATE FUNCTION public.ins_painel() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE fin boolean; resultado jsonb; BEGIN
 IF NOT public.tem('ativo') THEN RAISE EXCEPTION 'Sem acesso'; END IF;
 fin=public.tem('financeiro');
 WITH usado AS (
 SELECT m.pedido_id,m.insumo_id,-sum(m.quantidade) qtd FROM public.insumo_movimentos m JOIN public.insumos i ON i.id=m.insumo_id WHERE m.tipo IN ('consumo','estorno') AND i.categoria<>'filamento' GROUP BY 1,2
 UNION ALL
 SELECT pi.pedido_id,pi.insumo_id,pi.quantidade_por_peca*least(coalesce(nullif(p.dados->>'qtde','')::numeric,0),coalesce((SELECT sum(pr.pecas) FROM public.producao pr WHERE pr.pedido_id=pi.pedido_id),0)) qtd FROM public.pedido_insumos pi JOIN public.insumos i ON i.id=pi.insumo_id AND i.categoria='filamento' JOIN public.pedidos p ON p.id=pi.pedido_id),
 pendencias AS (SELECT pi.insumo_id,sum(greatest(pi.quantidade_por_peca*coalesce(nullif(p.dados->>'qtde','')::numeric,0)-coalesce(u.qtd,0),0)) qtd FROM public.pedido_insumos pi JOIN public.pedidos p ON p.id=pi.pedido_id LEFT JOIN usado u ON u.pedido_id=pi.pedido_id AND u.insumo_id=pi.insumo_id WHERE p.dados->>'status' NOT IN ('Cancelado','Entregue') GROUP BY 1)
 SELECT jsonb_build_object(
 'insumos',(SELECT coalesce(jsonb_agg(to_jsonb(i)||jsonb_build_object('necessidade_aberta',coalesce(p.qtd,0),'disponivel_planejado',i.saldo-coalesce(p.qtd,0))||CASE WHEN fin THEN jsonb_build_object('custo_medio',v.custo_medio,'referencia',v.referencia) ELSE '{}'::jsonb END ORDER BY i.nome),'[]') FROM public.insumos i LEFT JOIN pendencias p ON p.insumo_id=i.id LEFT JOIN public.insumo_valores v ON v.insumo_id=i.id),
 'planos',(SELECT coalesce(jsonb_agg(to_jsonb(p)),'[]') FROM public.pedido_insumos p),
 'usos',(SELECT coalesce(jsonb_agg(to_jsonb(u)),'[]') FROM usado u),
 'movimentos',(SELECT coalesce(jsonb_agg(to_jsonb(t)),'[]') FROM (SELECT m.* FROM public.insumo_movimentos m ORDER BY criado_em DESC,id DESC LIMIT 100)t),
 'custos',CASE WHEN fin THEN (SELECT coalesce(jsonb_agg(public._ins_custos(id)),'[]') FROM public.pedidos) ELSE '[]'::jsonb END) INTO resultado;
 RETURN resultado;
END $$;
ALTER FUNCTION public.fdm_exportar_snapshot() RENAME TO fdm_exportar_snapshot_fase1;
CREATE FUNCTION public._ins_exportar(p_tabela text) RETURNS jsonb LANGUAGE plpgsql STABLE SET search_path=public,pg_temp AS $$
DECLARE r jsonb; BEGIN
 IF p_tabela<>ALL(ARRAY['perfis','pedidos','despesas','pedido_custos','producao','equipamentos','materiais','fdm_custos','impressoes','movimentacoes_estoque','insumos','insumo_valores','insumo_operacoes','insumo_movimentos','insumo_movimento_valores','pedido_insumos','pedido_custos_insumos']) THEN RAISE EXCEPTION 'Tabela inválida'; END IF;
 -- Números de colunas são texto no arquivo: não perder precisão decimal ao baixar pelo navegador.
 EXECUTE format('SELECT coalesce(jsonb_agg(to_jsonb(t)||coalesce((SELECT jsonb_object_agg(key,to_jsonb(CASE WHEN key=''dados'' THEN value::text ELSE value #>> ''{}'' END)) FROM jsonb_each(to_jsonb(t)) WHERE key=''dados'' OR jsonb_typeof(value)=''number''),''{}''::jsonb) ORDER BY to_jsonb(t)::text),''[]''::jsonb) FROM public.%I t',p_tabela) INTO r;
 RETURN r;
END $$;
CREATE FUNCTION public.fdm_exportar_snapshot() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE r jsonb; t text;
BEGIN
 IF NOT public.tem('master') THEN RAISE EXCEPTION 'Apenas o master ativo pode exportar'; END IF;
 r=jsonb_build_object('app','HD3D-Fase1-snapshot','versao',2,'jsonb_em_texto',true,'exportado_em',now(),'limites',jsonb_build_array('Sem arquivos anexados','Sem senhas ou sessões de Auth','Restauração administrativa em ambiente separado'));
 FOREACH t IN ARRAY ARRAY['perfis','pedidos','despesas','pedido_custos','producao','equipamentos','materiais','fdm_custos','impressoes','movimentacoes_estoque','insumos','insumo_valores','insumo_operacoes','insumo_movimentos','insumo_movimento_valores','pedido_insumos','pedido_custos_insumos'] LOOP
  r=r||jsonb_build_object(t,public._ins_exportar(t));
 END LOOP; RETURN r;
END $$;
DO $$ DECLARE f record; BEGIN
 FOR f IN SELECT oid::regprocedure AS nome FROM pg_proc WHERE pronamespace='public'::regnamespace AND (proname LIKE '\_ins\_%' ESCAPE '\' OR proname LIKE 'ins\_%' ESCAPE '\' OR proname IN ('fdm_encerrar','fdm_estornar','fdm_encerrar_fase1','fdm_estornar_fase1','fdm_exportar_snapshot','fdm_exportar_snapshot_fase1')) LOOP
  EXECUTE 'REVOKE ALL ON FUNCTION '||f.nome||' FROM PUBLIC,anon,authenticated';
 END LOOP;
END $$;
GRANT EXECUTE ON FUNCTION public.ins_cadastrar(text,text,text,text),public.ins_configurar(uuid,numeric,boolean,numeric),public.ins_estoque(uuid,uuid,text,numeric,numeric,text),public.ins_consumir(uuid,uuid,jsonb,text),public.ins_estornar(uuid),public.ins_planejar(uuid,jsonb),public.ins_custo_pedido(uuid,numeric,numeric,text,boolean),public.ins_painel(),public.fdm_encerrar(uuid,text),public.fdm_estornar(uuid),public.fdm_exportar_snapshot() TO authenticated;
COMMIT;
