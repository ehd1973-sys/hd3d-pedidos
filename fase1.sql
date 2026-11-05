-- Fase 1. Aplicar primeiro em homologação. Não modifica as tabelas existentes.
BEGIN;
CREATE TABLE public.equipamentos (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), codigo text NOT NULL UNIQUE,
 nome text NOT NULL CHECK(length(trim(nome))>0),
 status text NOT NULL DEFAULT 'aguardando' CHECK(status IN ('ativa','aguardando','manutencao','inativa')),
 data_ativacao date, observacoes text NOT NULL DEFAULT '', criado_em timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.materiais (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), tipo text NOT NULL CHECK(length(trim(tipo))>0),
 fabricante text NOT NULL DEFAULT '', cor text NOT NULL DEFAULT '', ativo boolean NOT NULL DEFAULT true,
 estoque_inicial_g numeric CHECK(estoque_inicial_g>=0 AND estoque_inicial_g<1e12),
 criado_em timestamptz NOT NULL DEFAULT now()
);
-- Custos separados: usuários operacionais não recebem dados financeiros.
CREATE TABLE public.fdm_custos (
 id uuid PRIMARY KEY, categoria text NOT NULL CHECK(categoria IN ('equipamento','material')),
 valor numeric NOT NULL CHECK(valor>=0 AND valor<1e12), vida_util_meses integer CHECK(vida_util_meses>0),
 valor_residual numeric CHECK(valor_residual>=0 AND valor_residual<=valor)
);
CREATE TABLE public.impressoes (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), pedido_id uuid NOT NULL REFERENCES public.pedidos(id) ON DELETE RESTRICT,
 equipamento_id uuid NOT NULL REFERENCES public.equipamentos(id), material_id uuid NOT NULL REFERENCES public.materiais(id),
 status text NOT NULL DEFAULT 'planejada' CHECK(status IN ('planejada','imprimindo','concluida','falha','cancelada','estornada')),
 inicio_em timestamptz, fim_em timestamptz,
 tempo_fatiador_minutos numeric CHECK(tempo_fatiador_minutos>=0 AND tempo_fatiador_minutos<1e9),
 peso_peca_g numeric CHECK(peso_peca_g>=0 AND peso_peca_g<1e12),
 purga_g numeric CHECK(purga_g>=0 AND purga_g<1e12), desperdicio_g numeric CHECK(desperdicio_g>=0 AND desperdicio_g<1e12),
 falha_motivo text NOT NULL DEFAULT '', observacoes text NOT NULL DEFAULT '',
 usuario_id uuid NOT NULL DEFAULT auth.uid() REFERENCES public.perfis(id),
 criado_em timestamptz NOT NULL DEFAULT now(), atualizado_em timestamptz NOT NULL DEFAULT now(), fechado_em timestamptz,
 CHECK(fim_em IS NULL OR inicio_em IS NOT NULL AND fim_em>=inicio_em),
 CHECK(status<>'falha' OR length(trim(falha_motivo))>0)
);
CREATE INDEX ON public.impressoes(pedido_id);
CREATE INDEX ON public.impressoes(equipamento_id,inicio_em);
CREATE TABLE public.movimentacoes_estoque (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), material_id uuid NOT NULL REFERENCES public.materiais(id),
 impressao_id uuid NOT NULL REFERENCES public.impressoes(id), tipo text NOT NULL CHECK(tipo IN ('consumo','estorno')),
 quantidade_g numeric NOT NULL CHECK(quantidade_g>0 AND quantidade_g<1e12),
 usuario_id uuid NOT NULL REFERENCES public.perfis(id), criado_em timestamptz NOT NULL DEFAULT now(),
 UNIQUE(impressao_id,tipo)
);
CREATE INDEX ON public.movimentacoes_estoque(material_id);
ALTER TABLE public.equipamentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.materiais ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fdm_custos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.impressoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.movimentacoes_estoque ENABLE ROW LEVEL SECURITY;
CREATE POLICY equipamentos_ler ON public.equipamentos FOR SELECT TO authenticated USING(public.tem('ativo'));
CREATE POLICY equipamentos_master ON public.equipamentos FOR ALL TO authenticated USING(public.tem('master')) WITH CHECK(public.tem('master'));
CREATE POLICY materiais_ler ON public.materiais FOR SELECT TO authenticated USING(public.tem('ativo'));
CREATE POLICY materiais_master ON public.materiais FOR ALL TO authenticated USING(public.tem('master')) WITH CHECK(public.tem('master'));
CREATE POLICY custos_ler ON public.fdm_custos FOR SELECT TO authenticated USING(public.tem('financeiro'));
CREATE POLICY custos_master ON public.fdm_custos FOR ALL TO authenticated USING(public.tem('master')) WITH CHECK(public.tem('master'));
CREATE POLICY impressoes_ler ON public.impressoes FOR SELECT TO authenticated USING(public.tem('ativo'));
CREATE POLICY impressoes_criar ON public.impressoes FOR INSERT TO authenticated WITH CHECK(public.tem('producao') AND usuario_id=auth.uid() AND fechado_em IS NULL AND status IN ('planejada','imprimindo'));
CREATE POLICY impressoes_editar ON public.impressoes FOR UPDATE TO authenticated USING(public.tem('producao') AND fechado_em IS NULL) WITH CHECK(public.tem('producao'));
CREATE POLICY movimentos_ler ON public.movimentacoes_estoque FOR SELECT TO authenticated USING(public.tem('ativo'));
REVOKE ALL ON public.equipamentos,public.materiais,public.fdm_custos,public.impressoes,public.movimentacoes_estoque FROM anon,authenticated;
GRANT SELECT,INSERT,UPDATE ON public.equipamentos,public.materiais,public.fdm_custos TO authenticated;
GRANT SELECT,INSERT ON public.impressoes TO authenticated;
GRANT UPDATE(pedido_id,equipamento_id,material_id,status,inicio_em,fim_em,tempo_fatiador_minutos,peso_peca_g,purga_g,desperdicio_g,falha_motivo,observacoes) ON public.impressoes TO authenticated;
GRANT SELECT ON public.movimentacoes_estoque TO authenticated;

CREATE FUNCTION public.fdm_validar_impressao() RETURNS trigger LANGUAGE plpgsql SET search_path=public AS $$
BEGIN
 IF TG_OP='UPDATE' AND OLD.fechado_em IS NOT NULL AND current_user<>'postgres' THEN RAISE EXCEPTION 'Impressão encerrada: use estorno'; END IF;
 IF NEW.fechado_em IS NULL AND NEW.status NOT IN ('planejada','imprimindo') THEN RAISE EXCEPTION 'Use a função de encerramento'; END IF;
 IF NEW.fechado_em IS NULL THEN
  IF NOT EXISTS(SELECT 1 FROM public.pedidos WHERE id=NEW.pedido_id AND coalesce(dados->>'status','')<>'Cancelado') THEN RAISE EXCEPTION 'Pedido indisponível ou cancelado'; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.equipamentos WHERE id=NEW.equipamento_id AND status='ativa') THEN RAISE EXCEPTION 'Impressora não está ativa'; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.materiais WHERE id=NEW.material_id AND ativo) THEN RAISE EXCEPTION 'Material inativo'; END IF;
 END IF;
 NEW.atualizado_em=now(); RETURN NEW;
END $$;
CREATE TRIGGER fdm_validar BEFORE INSERT OR UPDATE ON public.impressoes FOR EACH ROW EXECUTE FUNCTION public.fdm_validar_impressao();

CREATE FUNCTION public.fdm_encerrar(p_id uuid,p_status text) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE r public.impressoes; massa numeric;
BEGIN
 IF NOT public.tem('producao') THEN RAISE EXCEPTION 'Sem permissão de produção'; END IF;
 IF p_status IS NULL OR p_status NOT IN ('concluida','falha','cancelada') THEN RAISE EXCEPTION 'Status inválido'; END IF;
 SELECT * INTO r FROM public.impressoes WHERE id=p_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Impressão não encontrada'; END IF;
 IF r.fechado_em IS NOT NULL THEN
  IF r.status=p_status THEN RETURN; END IF;
  RAISE EXCEPTION 'Impressão já encerrada';
 END IF;
 IF p_status IN ('concluida','falha') AND (r.inicio_em IS NULL OR r.fim_em IS NULL) THEN RAISE EXCEPTION 'Informe início e término'; END IF;
 IF p_status='falha' AND length(trim(r.falha_motivo))=0 THEN RAISE EXCEPTION 'Informe o motivo da falha'; END IF;
 -- Todos os componentes devem ser medidos para efetivar consumo; nulos nunca viram zero.
 IF r.peso_peca_g IS NULL OR r.purga_g IS NULL OR r.desperdicio_g IS NULL THEN RAISE EXCEPTION 'Meça peça, purga e desperdício (zero apenas quando medido)'; END IF;
 massa=r.peso_peca_g+r.purga_g+r.desperdicio_g;
 PERFORM 1 FROM public.materiais WHERE id=r.material_id FOR UPDATE;
 IF massa>0 THEN INSERT INTO public.movimentacoes_estoque(material_id,impressao_id,tipo,quantidade_g,usuario_id) VALUES(r.material_id,r.id,'consumo',massa,auth.uid()); END IF;
 UPDATE public.impressoes SET status=p_status,fechado_em=now() WHERE id=r.id;
END $$;
CREATE FUNCTION public.fdm_estornar(p_id uuid) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE r public.impressoes; massa numeric;
BEGIN
 IF NOT public.tem('producao') THEN RAISE EXCEPTION 'Sem permissão de produção'; END IF;
 SELECT * INTO r FROM public.impressoes WHERE id=p_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Impressão não encontrada'; END IF;
 IF r.status='estornada' THEN RETURN; END IF;
 IF r.fechado_em IS NULL THEN RAISE EXCEPTION 'Encerre a impressão primeiro'; END IF;
 PERFORM 1 FROM public.materiais WHERE id=r.material_id FOR UPDATE;
 SELECT quantidade_g INTO massa FROM public.movimentacoes_estoque WHERE impressao_id=r.id AND tipo='consumo';
 IF massa>0 THEN INSERT INTO public.movimentacoes_estoque(material_id,impressao_id,tipo,quantidade_g,usuario_id) VALUES(r.material_id,r.id,'estorno',massa,auth.uid()); END IF;
 UPDATE public.impressoes SET status='estornada' WHERE id=r.id;
END $$;
REVOKE ALL ON FUNCTION public.fdm_encerrar(uuid,text),public.fdm_estornar(uuid),public.fdm_validar_impressao() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.fdm_encerrar(uuid,text),public.fdm_estornar(uuid) TO authenticated;
INSERT INTO public.equipamentos(id,codigo,nome,status) VALUES
 ('00000000-0000-4000-8000-000000000001','IMP-001','Bambu Lab A1 + AMS Lite','ativa'),
 ('00000000-0000-4000-8000-000000000002','IMP-002','QIDI Q2 + sistema multicolor','aguardando'),
 ('00000000-0000-4000-8000-000000000003','IMP-003','Anycubic Kobra X + sistema multicolor','aguardando');
INSERT INTO public.materiais(id,tipo) VALUES
 ('00000000-0000-4000-8000-000000000011','PLA'),('00000000-0000-4000-8000-000000000012','PETG'),('00000000-0000-4000-8000-000000000013','TPU');
INSERT INTO public.fdm_custos(id,categoria,valor,vida_util_meses) VALUES
 ('00000000-0000-4000-8000-000000000001','equipamento',5000,48),('00000000-0000-4000-8000-000000000002','equipamento',5500,48),('00000000-0000-4000-8000-000000000003','equipamento',3800,48),
 ('00000000-0000-4000-8000-000000000011','material',90,NULL),('00000000-0000-4000-8000-000000000012','material',70,NULL),('00000000-0000-4000-8000-000000000013','material',100,NULL);
COMMIT;
