-- Correção separada para revisão. Ainda não aplicada na origem.
-- Revoga somente esvaziamento integral; mantém permissões das operações do aplicativo.
BEGIN;
REVOKE TRUNCATE ON TABLE public.perfis,public.pedidos,public.despesas,public.pedido_custos,public.producao FROM anon,authenticated;
COMMIT;
