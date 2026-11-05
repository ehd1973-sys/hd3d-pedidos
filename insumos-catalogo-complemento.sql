-- Apenas para homologação que já recebeu a revisão anterior de insumos.sql.
BEGIN;
CREATE OR REPLACE FUNCTION public.ins_editar(p_id uuid,p_codigo text,p_nome text) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE i public.insumos; BEGIN
 IF NOT public.tem('master') THEN RAISE EXCEPTION 'Apenas master pode editar o cadastro'; END IF;
 IF p_codigo IS NULL OR p_nome IS NULL OR length(trim(p_codigo)) NOT BETWEEN 1 AND 80 OR length(trim(p_nome)) NOT BETWEEN 1 AND 200 THEN RAISE EXCEPTION 'Informe código e nome válidos'; END IF;
 PERFORM 1 FROM public.materiais WHERE id=(SELECT material_id FROM public.insumos WHERE id=p_id) FOR UPDATE;
 SELECT * INTO i FROM public.insumos WHERE id=p_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Insumo não encontrado'; END IF;
 UPDATE public.insumos SET codigo=trim(p_codigo),nome=trim(p_nome) WHERE id=p_id;
 INSERT INTO public.insumo_operacoes(id,autor,tipo,dados) VALUES(gen_random_uuid(),auth.uid(),'editar_cadastro',jsonb_build_object('insumo',p_id,'codigo_anterior',i.codigo,'nome_anterior',i.nome,'codigo',trim(p_codigo),'nome',trim(p_nome)));
END $$;
CREATE OR REPLACE FUNCTION public.ins_retirar(p_id uuid,p_retirado boolean) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE i public.insumos; BEGIN
 IF NOT public.tem('master') THEN RAISE EXCEPTION 'Apenas master pode retirar ou restaurar cadastros'; END IF;
 IF p_retirado IS NULL THEN RAISE EXCEPTION 'Informe a ação'; END IF;
 PERFORM 1 FROM public.materiais WHERE id=(SELECT material_id FROM public.insumos WHERE id=p_id) FOR UPDATE;
 SELECT * INTO i FROM public.insumos WHERE id=p_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Insumo não encontrado'; END IF;
 IF i.ativo=NOT p_retirado THEN RETURN; END IF;
 IF p_retirado AND coalesce(i.saldo,0)<>0 THEN RAISE EXCEPTION 'Há saldo físico. Confira e corrija o estoque antes de retirar o cadastro'; END IF;
 IF p_retirado AND EXISTS(SELECT 1 FROM public.pedido_insumos pi JOIN public.pedidos p ON p.id=pi.pedido_id WHERE pi.insumo_id=p_id AND p.dados->>'status' NOT IN ('Cancelado','Entregue')) THEN RAISE EXCEPTION 'O insumo está planejado em pedido aberto. Corrija a composição antes de retirar'; END IF;
 IF p_retirado AND EXISTS(SELECT 1 FROM public.impressoes WHERE material_id=i.material_id AND status IN ('planejada','imprimindo')) THEN RAISE EXCEPTION 'Há impressão aberta com este material'; END IF;
 UPDATE public.insumos SET ativo=NOT p_retirado WHERE id=p_id;
 UPDATE public.materiais SET ativo=NOT p_retirado WHERE id=i.material_id;
 INSERT INTO public.insumo_operacoes(id,autor,tipo,dados) VALUES(gen_random_uuid(),auth.uid(),CASE WHEN p_retirado THEN 'retirar_cadastro' ELSE 'restaurar_cadastro' END,jsonb_build_object('insumo',p_id,'codigo',i.codigo,'nome',i.nome));
END $$;
CREATE OR REPLACE FUNCTION public.ins_configurar(p_id uuid,p_minimo numeric,p_ativo boolean,p_referencia numeric) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
BEGIN
 IF NOT public.tem('master') THEN RAISE EXCEPTION 'Apenas master pode configurar insumos'; END IF;
 -- Mesma ordem de bloqueio usada pelo encerramento FDM: material, depois insumo.
 PERFORM 1 FROM public.materiais WHERE id=(SELECT material_id FROM public.insumos WHERE id=p_id) FOR UPDATE;
 IF EXISTS(SELECT 1 FROM public.insumos WHERE id=p_id AND ativo IS DISTINCT FROM p_ativo) THEN PERFORM public.ins_retirar(p_id,NOT p_ativo); END IF;
 UPDATE public.insumos SET minimo=p_minimo,ativo=p_ativo WHERE id=p_id;
 IF NOT FOUND THEN RAISE EXCEPTION 'Insumo não encontrado'; END IF;
 UPDATE public.insumo_valores SET referencia=p_referencia WHERE insumo_id=p_id;
 UPDATE public.materiais SET ativo=p_ativo WHERE id=(SELECT material_id FROM public.insumos WHERE id=p_id);
 INSERT INTO public.insumo_operacoes(id,autor,tipo,dados) VALUES(gen_random_uuid(),auth.uid(),'configuracao',jsonb_build_object('insumo',p_id,'minimo',p_minimo,'ativo',p_ativo,'referencia',p_referencia));
END $$;
CREATE OR REPLACE FUNCTION public.ins_planejar(p_pedido uuid,p_itens jsonb) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
BEGIN
 IF NOT (public.tem('editar') OR public.tem('producao')) THEN RAISE EXCEPTION 'Sem permissão de planejamento'; END IF;
 PERFORM 1 FROM public.pedidos WHERE id=p_pedido FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Pedido não encontrado'; END IF;
 IF p_itens IS NULL OR jsonb_typeof(p_itens)<>'array' THEN RAISE EXCEPTION 'Composição inválida'; END IF;
 PERFORM 1 FROM public.insumos WHERE id IN (SELECT x.insumo_id FROM jsonb_to_recordset(p_itens) AS x(insumo_id uuid)) ORDER BY id FOR UPDATE;
 IF EXISTS(SELECT 1 FROM jsonb_to_recordset(p_itens) AS x(insumo_id uuid) LEFT JOIN public.insumos i ON i.id=x.insumo_id WHERE i.id IS NULL OR NOT i.ativo) THEN RAISE EXCEPTION 'Retire da composição os insumos inexistentes ou retirados do catálogo'; END IF;
 INSERT INTO public.insumo_operacoes(id,autor,tipo,pedido_id,dados) VALUES(gen_random_uuid(),auth.uid(),'planejamento',p_pedido,jsonb_build_object('antes',(SELECT coalesce(jsonb_agg(to_jsonb(t)),'[]') FROM public.pedido_insumos t WHERE pedido_id=p_pedido),'depois',p_itens));
 DELETE FROM public.pedido_insumos WHERE pedido_id=p_pedido;
 INSERT INTO public.pedido_insumos SELECT p_pedido,insumo_id,quantidade_por_peca FROM jsonb_to_recordset(p_itens) AS x(insumo_id uuid,quantidade_por_peca numeric);
END $$;
REVOKE ALL ON FUNCTION public.ins_editar(uuid,text,text),public.ins_retirar(uuid,boolean) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.ins_editar(uuid,text,text),public.ins_retirar(uuid,boolean) TO authenticated;
COMMIT;
