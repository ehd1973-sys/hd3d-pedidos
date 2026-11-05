-- Executar APENAS em homologação após preservar registros novos.
-- Remove permanentemente somente o módulo FDM. Não executar em produção sem revisão.
BEGIN;
DROP FUNCTION IF EXISTS public.fdm_exportar_snapshot();
DROP FUNCTION public.fdm_encerrar(uuid,text);
DROP FUNCTION public.fdm_estornar(uuid);
DROP TABLE public.movimentacoes_estoque;
DROP TABLE public.impressoes;
DROP FUNCTION public.fdm_validar_impressao();
DROP TABLE public.fdm_custos;
DROP TABLE public.materiais;
DROP TABLE public.equipamentos;
COMMIT;
