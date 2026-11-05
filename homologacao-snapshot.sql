-- Somente homologação. Todas as alterações de perfil são revertidas.
BEGIN;
DO $$ BEGIN IF NOT EXISTS(SELECT FROM public.pedidos WHERE dados->>'cliente'='Cliente de homologação') THEN RAISE EXCEPTION 'Ambiente de teste não reconhecido'; END IF; END $$;
SELECT set_config('request.jwt.claim.sub',(SELECT id::text FROM public.perfis WHERE master AND ativo LIMIT 1),true);
UPDATE public.perfis SET master=false,ativo=true,producao=false,ver_financeiro=false WHERE id=auth.uid();
SET LOCAL ROLE authenticated;
DO $$ BEGIN
 BEGIN
  PERFORM public.fdm_exportar_snapshot();
  RAISE EXCEPTION 'Perfil não master exportou';
 EXCEPTION WHEN raise_exception THEN
  IF SQLERRM<>'Apenas o master ativo pode exportar' THEN RAISE; END IF;
 END;
END $$;
RESET ROLE;
UPDATE public.perfis SET master=false,ativo=true,producao=true,ver_financeiro=false WHERE id=auth.uid();
SET LOCAL ROLE authenticated;
DO $$ BEGIN
 BEGIN
  PERFORM public.fdm_exportar_snapshot();
  RAISE EXCEPTION 'Perfil não master exportou';
 EXCEPTION WHEN raise_exception THEN
  IF SQLERRM<>'Apenas o master ativo pode exportar' THEN RAISE; END IF;
 END;
END $$;
RESET ROLE;
UPDATE public.perfis SET master=false,ativo=true,producao=false,ver_financeiro=true WHERE id=auth.uid();
SET LOCAL ROLE authenticated;
DO $$ BEGIN
 BEGIN
  PERFORM public.fdm_exportar_snapshot();
  RAISE EXCEPTION 'Perfil não master exportou';
 EXCEPTION WHEN raise_exception THEN
  IF SQLERRM<>'Apenas o master ativo pode exportar' THEN RAISE; END IF;
 END;
END $$;
RESET ROLE;
UPDATE public.perfis SET master=false,ativo=false,producao=false,ver_financeiro=false WHERE id=auth.uid();
SET LOCAL ROLE authenticated;
DO $$ BEGIN
 BEGIN
  PERFORM public.fdm_exportar_snapshot();
  RAISE EXCEPTION 'Perfil não master exportou';
 EXCEPTION WHEN raise_exception THEN
  IF SQLERRM<>'Apenas o master ativo pode exportar' THEN RAISE; END IF;
 END;
END $$;
RESET ROLE;ROLLBACK;
BEGIN;
SELECT set_config('request.jwt.claim.sub',(SELECT id::text FROM public.perfis WHERE master AND ativo LIMIT 1),true);
SET LOCAL ROLE authenticated;
WITH copia AS (SELECT public.fdm_exportar_snapshot() d)
SELECT d->>'app' formato,jsonb_array_length(d->'equipamentos') impressoras,
jsonb_array_length(d->'impressoes') impressoes,jsonb_array_length(d->'movimentacoes_estoque') movimentos,
'Quatro perfis recusados; master exporta; alterações revertidas' resultado FROM copia;
ROLLBACK;
