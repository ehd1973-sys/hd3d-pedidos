-- Complemento da Fase 1: exportação consistente das dez tabelas da aplicação.
-- Não inclui arquivos binários do Storage nem credenciais de Auth.
BEGIN;
CREATE OR REPLACE FUNCTION public.fdm_exportar_snapshot() RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=public,pg_temp AS $$
BEGIN
 IF NOT public.tem('master') THEN RAISE EXCEPTION 'Apenas o master ativo pode exportar'; END IF;
 RETURN jsonb_build_object(
  'app','HD3D-Fase1-snapshot','versao',1,'exportado_em',now(),
  'perfis',(SELECT coalesce(jsonb_agg(to_jsonb(t) ORDER BY id),'[]'::jsonb) FROM public.perfis t),
  'pedidos',(SELECT coalesce(jsonb_agg(to_jsonb(t) ORDER BY id),'[]'::jsonb) FROM public.pedidos t),
  'despesas',(SELECT coalesce(jsonb_agg(to_jsonb(t) ORDER BY id),'[]'::jsonb) FROM public.despesas t),
  'pedido_custos',(SELECT coalesce(jsonb_agg(to_jsonb(t) ORDER BY pedido_id),'[]'::jsonb) FROM public.pedido_custos t),
  'producao',(SELECT coalesce(jsonb_agg(to_jsonb(t) ORDER BY id),'[]'::jsonb) FROM public.producao t),
  'equipamentos',(SELECT coalesce(jsonb_agg(to_jsonb(t) ORDER BY id),'[]'::jsonb) FROM public.equipamentos t),
  'materiais',(SELECT coalesce(jsonb_agg(to_jsonb(t) ORDER BY id),'[]'::jsonb) FROM public.materiais t),
  'fdm_custos',(SELECT coalesce(jsonb_agg(to_jsonb(t) ORDER BY id),'[]'::jsonb) FROM public.fdm_custos t),
  'impressoes',(SELECT coalesce(jsonb_agg(to_jsonb(t) ORDER BY id),'[]'::jsonb) FROM public.impressoes t),
  'movimentacoes_estoque',(SELECT coalesce(jsonb_agg(to_jsonb(t) ORDER BY id),'[]'::jsonb) FROM public.movimentacoes_estoque t),
  'limites',jsonb_build_array('Sem arquivos anexados','Sem senhas ou sessões de Auth','Restauração administrativa em ambiente separado')
 );
END $$;
REVOKE ALL ON FUNCTION public.fdm_exportar_snapshot() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.fdm_exportar_snapshot() TO authenticated;
COMMIT;
