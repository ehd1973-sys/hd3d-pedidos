# Insumos, estoque e custo de produção — v1.1

## O que muda

Insumos e estoque reúne filamentos, argolas, correntinhas, conjuntos prontos, embalagens e outros materiais. O cadastro antigo de filamentos fica integrado a essa tela. Impressoras e apontamentos continuam disponíveis.

O catálogo é livre: cadastre qualquer insumo e suas variantes, sem depender de itens pré-definidos. Apenas os filamentos já existentes são integrados automaticamente. Nenhum cadastro novo recebe saldo ou preço inventado.

## Preparar o estoque

1. Como administrador, confira cada item em Insumos e estoque. Filamento é controlado em gramas; peças e conjuntos, normalmente em unidades. Também existem metro e mililitro.
2. Use Contagem para informar a quantidade física atual e o custo atribuído a cada unidade. Exemplo: R$90/kg de filamento correspondem a R$0,09/g. Zero deve ser informado somente quando for o valor correto.
3. Em Configurar, informe mínimo e, se necessário, preço de referência para orçamento. Referência não é custo real de uma compra. Preço médio conhecido do estoque tem prioridade no planejamento.
4. Depois, use Compra / entrada para registrar reposições. Para um pacote com 100 argolas, informe 100 unidades e o valor total pago pelo pacote, incluindo frete. O sistema calcula o custo médio ponderado.

Uma compra não substitui a contagem inicial desconhecida. O consumo exige saldo contado e custo atribuído; não permite estoque negativo. Contagem também corrige diferenças físicas, preservando o histórico. Entradas de estoque não geram automaticamente despesas financeiras na tela antiga: compra de estoque e custo do material consumido são registros distintos.

## Composição e previsão

1. Abra Custo de produção e escolha o pedido.
2. Informe a composição por peça. Inclua filamento estimado, ferragens, embalagem e demais insumos utilizados.
3. Para um chaveiro montado com peças avulsas, por exemplo, informe uma argola e uma correntinha. Para o conjunto comprado pronto, informe o conjunto; não some novamente os mesmos componentes. As quantidades são configuradas por você.
4. Salve a composição. A necessidade total usa a quantidade do pedido; saldos e faltas aparecem em Insumos e estoque.
5. Informe outros custos planejados quando conhecidos, como energia, mão de obra, depreciação e acabamento. Informe zero explicitamente quando não houver outros custos nesse orçamento.
6. Se quiser usar essa previsão nas telas antigas de pedidos e resumo, clique em Aplicar estimativa ao custo do pedido e confirme. Isso substitui o custo unitário anterior. O valor aplicado aceita seis casas decimais; mudanças futuras de preço não o alteram automaticamente.

O disponível após planejamento é o saldo físico menos as necessidades remanescentes de todos os pedidos abertos. É uma previsão, sem reserva exclusiva por pedido. Para filamento, a necessidade remanescente considera as peças já lançadas na tela Produção; falhas e purga não são peças atendidas. Para componentes e conjuntos, considera o consumo líquido de montagem. Pedidos entregues/cancelados saem da necessidade aberta.

## Consumo efetivo e custo histórico

- Ao encerrar uma impressão, peça + purga + desperdício são baixados do filamento automaticamente. Não repita essa baixa no consumo manual.
- Para montagem e outros usos, escolha o pedido em Custo de produção e registre as quantidades efetivamente utilizadas no lote. Pode incluir vários insumos em uma única operação.
- A baixa de um lote é integral: se algum item não tiver saldo ou custo conferido, nenhum item é baixado. Repetir a mesma solicitação não duplica a movimentação.
- Cada consumo guarda o custo médio daquela data. Uma reposição posterior pode mudar a próxima previsão, mas não reescreve o custo dos materiais já consumidos.
- Continue lançando peças/logos na tela Produção. Consumo e impressão não duplicam essa contagem automaticamente.

O painel mostra o custo real acumulado dos insumos e os outros custos reais declarados. Esse acumulado pode corresponder somente a parte da fabricação; não é automaticamente o custo completo do pedido nem lucro líquido. Os indicadores antigos continuam usando o custo unitário aplicado/editado no pedido, que pode ser uma estimativa.

## Estorno e histórico anterior

Estornar lote devolve todos os itens daquela operação e preserva o custo original. Repetir não duplica a devolução. Impressões são estornadas na tela Impressões. Contagens e compras são corrigidas por nova conferência, sem apagar o histórico.

Uma impressão encerrada antes da integração pode não ter custo histórico recuperável. Seu estorno mantém o registro e exige recontar o filamento e conferir o custo; o sistema não inventa um valor passado. O painel sinaliza trabalhos anteriores sem custo recuperado. Estornos não desfazem automaticamente as quantidades de peças/logos lançadas na tela Produção.

## Permissões e cópia

Usuários ativos consultam catálogo, saldo, composição e movimentos. Produção permite consumir e estornar. Despesas permite registrar compras. Master cadastra, configura e faz contagem. Valores financeiros e custos ficam visíveis somente para financeiro/master; aplicar previsão ao pedido exige financeiro e edição.

O administrador pode exportar as 17 tabelas na tela Backup. A versão 2 preserva números e campos JSON como texto no arquivo para manter precisão decimal na recuperação. Use o conversor atualizado snapshot-para-sql.mjs, sem editar manualmente esses campos. Não use o importador da versão antiga. Arquivos binários, senhas e configuração integral do Supabase continuam separados.

Para recuperar em destino vazio: restaurar estrutura original, fase1-estrutura-recuperacao.sql, fase1-fechamento.sql e insumos-estrutura-recuperacao.sql; depois gerar/aplicar o SQL da cópia com o conversor atualizado. Os usuários Auth devem ser recuperados por procedimento administrativo suportado. A recuperação local das tabelas foi testada; não substitui recuperação integral dos serviços gerenciados.

## Cadastro livre durante a produção e correções

Em Custo de produção, o administrador pode usar **Cadastrar novo insumo aqui**, informar código, nome, categoria e unidade e voltar ao lote sem perder as quantidades preenchidas. O novo item entra na lista de consumo. Informe seu estoque e custo reais antes da baixa. O consumo de um lote não exige composição previamente salva: selecione os itens usados e suas quantidades.

Em Insumos e estoque, **Editar cadastro** corrige nome e código, com auditoria. A unidade não muda para preservar o significado de saldos e custos; se ela estiver errada, retire o cadastro e crie outro. **Excluir do catálogo** retira o item das novas escolhas de forma reversível, preservando registros e custos históricos. Itens com saldo físico, composição em pedido aberto ou impressão pendente precisam ser corrigidos antes. **Mostrar itens retirados do catálogo** permite localizar e restaurar o cadastro.

Erro em consumo é corrigido por **Estornar lote** (ou estorno da impressão); erro de quantidade física é corrigido por **Contagem**, com motivo registrado. Retirar um cadastro não desfaz suas movimentações.
