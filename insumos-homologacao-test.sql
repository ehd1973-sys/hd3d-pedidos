-- Exclusivamente homologação; perfis e consumos temporários revertidos.
BEGIN;
DO $$ BEGIN IF NOT EXISTS(SELECT FROM public.pedidos WHERE dados->>'cliente'='Cliente de homologação') THEN RAISE EXCEPTION 'Somente homologação'; END IF; END $$;
SELECT set_config('request.jwt.claim.sub',(SELECT id::text FROM public.perfis WHERE master AND ativo LIMIT 1),true);
UPDATE public.perfis SET master=false,ativo=true,producao=false,editar=false,despesas=false,ver_financeiro=false WHERE id=auth.uid();
SET LOCAL ROLE authenticated;
DO $$ DECLARE d jsonb; BEGIN
 d=public.ins_painel(); IF jsonb_array_length(d->'insumos')<6 THEN RAISE EXCEPTION 'Catálogo incompleto'; END IF;
 IF EXISTS(SELECT FROM public.insumo_valores) OR EXISTS(SELECT FROM public.insumo_movimento_valores) THEN RAISE EXCEPTION 'Preço exposto'; END IF;
 IF (d->'insumos'->0) ? 'custo_medio' OR jsonb_array_length(d->'custos')<>0 THEN RAISE EXCEPTION 'Painel expôs valores'; END IF;
 BEGIN PERFORM public.ins_configurar((SELECT id FROM public.insumos LIMIT 1),0,true,1); RAISE EXCEPTION 'Perfil configurou insumo'; EXCEPTION WHEN raise_exception THEN IF SQLERRM<>'Apenas master pode configurar insumos' THEN RAISE; END IF; END;
 END $$;
RESET ROLE;
UPDATE public.perfis SET master=false,ativo=true,producao=true,editar=false,despesas=false,ver_financeiro=false WHERE id=auth.uid();
SET LOCAL ROLE authenticated;
DO $$ DECLARE d jsonb; BEGIN
 d=public.ins_painel(); IF jsonb_array_length(d->'insumos')<6 THEN RAISE EXCEPTION 'Catálogo incompleto'; END IF;
 IF EXISTS(SELECT FROM public.insumo_valores) OR EXISTS(SELECT FROM public.insumo_movimento_valores) THEN RAISE EXCEPTION 'Preço exposto'; END IF;
 IF (d->'insumos'->0) ? 'custo_medio' OR jsonb_array_length(d->'custos')<>0 THEN RAISE EXCEPTION 'Painel expôs valores'; END IF;
 BEGIN PERFORM public.ins_configurar((SELECT id FROM public.insumos LIMIT 1),0,true,1); RAISE EXCEPTION 'Perfil configurou insumo'; EXCEPTION WHEN raise_exception THEN IF SQLERRM<>'Apenas master pode configurar insumos' THEN RAISE; END IF; END;
 END $$;
RESET ROLE;
UPDATE public.perfis SET master=false,ativo=true,producao=false,editar=false,despesas=false,ver_financeiro=true WHERE id=auth.uid();
SET LOCAL ROLE authenticated;
DO $$ DECLARE d jsonb; BEGIN
 d=public.ins_painel(); IF jsonb_array_length(d->'insumos')<6 THEN RAISE EXCEPTION 'Catálogo incompleto'; END IF;
 IF NOT EXISTS(SELECT FROM public.insumo_valores) THEN RAISE EXCEPTION 'Financeiro não lê preços'; END IF;

 BEGIN PERFORM public.ins_configurar((SELECT id FROM public.insumos LIMIT 1),0,true,1); RAISE EXCEPTION 'Perfil configurou insumo'; EXCEPTION WHEN raise_exception THEN IF SQLERRM<>'Apenas master pode configurar insumos' THEN RAISE; END IF; END;
 END $$;
RESET ROLE;
UPDATE public.perfis SET master=false,ativo=false,producao=false,editar=false,despesas=false,ver_financeiro=false WHERE id=auth.uid();
SET LOCAL ROLE authenticated;
DO $$ DECLARE d jsonb; BEGIN
 BEGIN PERFORM public.ins_painel(); RAISE EXCEPTION 'Inativo recebeu painel'; EXCEPTION WHEN raise_exception THEN IF SQLERRM<>'Sem acesso' THEN RAISE; END IF; END;
 IF EXISTS(SELECT FROM public.insumo_valores) OR EXISTS(SELECT FROM public.insumo_movimento_valores) THEN RAISE EXCEPTION 'Preço exposto'; END IF;

 BEGIN PERFORM public.ins_configurar((SELECT id FROM public.insumos LIMIT 1),0,true,1); RAISE EXCEPTION 'Perfil configurou insumo'; EXCEPTION WHEN raise_exception THEN IF SQLERRM<>'Apenas master pode configurar insumos' THEN RAISE; END IF; END;
 END $$;
RESET ROLE;
ROLLBACK;
SELECT 'Leitor, operador, financeiro e inativo: OK; perfis preservados' resultado,
 (SELECT count(*) FROM pg_class WHERE relnamespace='public'::regnamespace AND relkind='r' AND relrowsecurity) tabelas_rls,
 (SELECT bool_or(has_function_privilege('anon',oid,'EXECUTE')) FROM pg_proc WHERE pronamespace='public'::regnamespace AND (proname LIKE 'ins\_%' ESCAPE '\' OR proname LIKE '\_ins\_%' ESCAPE '\')) anon_tem_acesso;
