# HD3D — Insumos, estoque e custos, versão 1.1

Incremento instalado e publicado no sistema em uso em 05/11/2026, após autorização do responsável. Registro em [PUBLICACAO-INSUMOS.md](PUBLICACAO-INSUMOS.md). Permite argolas e correntinhas avulsas, conjuntos prontos, filamentos, embalagens e outros insumos. Cada item tem unidade, contagem, compras, custo médio e histórico de consumo/estorno. A composição por peça calcula necessidade e custo previsto do pedido; os consumos preservam o custo da época.

Operação: [MANUAL-INSUMOS.md](MANUAL-INSUMOS.md). Instalação e validação: [IMPLANTACAO-INSUMOS.md](IMPLANTACAO-INSUMOS.md). Aplicar `insumos.sql` uma vez sobre a Fase 1; publicar `index.html`, `fdm.js` e `insumos.js` juntos. Não há lista obrigatória de ferragens pré-cadastradas. Cadastre os itens necessários, sem saldo nem preço presumidos.

Antes de consumir ou encerrar novas impressões, informar contagem e custo reais. Saldo insuficiente bloqueia a baixa. A disponibilidade projetada desconta a necessidade dos pedidos abertos e pode indicar falta; não é uma reserva exclusiva. A produção de peças continua sendo apontada na tela Produção. Custo apurado acumula os consumos e despesas adicionais informadas; não representa lucro líquido. O custo unitário usado nos relatórios antigos só muda mediante aplicação explícita da previsão.

`npm test` executa as validações antigas e novas, incluindo recuperação exata de 17 tabelas e proteção dos custos por perfil. A cópia exportada pela interface de homologação também foi recuperada e comparada. Dois acessos simultâneos ao mesmo saldo foram testados no Supabase: a segunda baixa excedente foi recusada. Os dados de homologação são fictícios e não devem ser copiados para produção.

## Histórico da Fase 1

O registro abaixo descreve a versão 1.0 publicada e seus limites naquela entrega; o incremento acima substitui as limitações de insumos, reposição, custos e saldo negativo para novos consumos.
# HD3D — Fase 1, versão 1.0.0

Impressoras, materiais e apontamento FDM por trabalho, vinculados aos pedidos existentes. A contagem de peças/logos continua na tela Produção. Instalada no projeto HD3D Pedidos e publicada em 05/11/2026 após autorização do responsável. Endereço: https://ehd1973-sys.github.io/hd3d-pedidos/ . Registro em `PUBLICACAO-FASE1.md`.

## Entrega

- `index.html` e `fdm.js`: aplicação existente e novas telas.
- `fase1.sql`: migração aditiva, permissões e referências iniciais; aplicar uma vez.
- `fase1-fechamento.sql`: exportação das dez tabelas, exclusiva de master ativo; reexecutável.
- `seguranca-corrigir-truncate.sql`: correção separada de permissão antiga, para revisão na implantação.
- `MANUAL-FASE1.md`, `IMPLANTACAO.md`, `ACEITE-FASE1.md`, `HOMOLOGACAO.md`: operação, instalação, critérios e testes.
- `snapshot-para-sql.mjs` e `fase1-estrutura-recuperacao.sql`: recuperação administrativa dos dados em destino vazio.
- `rollback-fase1.sql`: remoção destrutiva do módulo; nunca executar automaticamente.

## Regras

Master cadastra impressoras/materiais e altera o estado das impressoras. Usuário ativo consulta; permissão Produção permite incluir, editar trabalhos abertos, encerrar e estornar. Custos ficam em tabela separada, restrita a financeiro/master. As regras são aplicadas no servidor.

Encerramento registra uma saída em transação. Repetições e chamadas simultâneas não duplicam consumo. Estorno preserva a saída e cria entrada compensatória uma vez. Registros encerrados não são editáveis pelo usuário. Duração e massas desconhecidas aparecem como “Não medido”.

A1 ativa; QIDI Q2 e Kobra X aguardando ativação. PLA R$90/kg, PETG R$70/kg, TPU R$100/kg. Sem cor, fabricante, saldo ou histórico inventados. Aquisição e vida útil de 48 meses vêm da auditoria; residual não definido. Cadastros novos não recebem preços presumidos.

Energia aparece só como estimativa para IMP-001/PLA com duração registrada, a 95 W e R$0,89/kWh. Não representa medição ou lucro líquido. Estornos ficam fora do total de tempo por impressora.

## Validação

Passaram: recuperação das cinco tabelas antigas, integridade dos seis anexos, migração, validações, permissões, encerramento/estorno repetidos e simultâneos, preservação das quantidades, inclusão/edição/persistência pela interface e leitura em celular.

A cópia das dez tabelas baixada pelo aplicativo de homologação foi restaurada localmente e comparada, incluindo três impressões e seis movimentos. Master exporta; leitor, operador, financeiro e inativo são recusados. Não inclui arquivos binários, senhas ou configuração integral do Supabase.

Repetição local: `npm ci`, `node test.mjs`, `node ui-test.mjs`, `node homologacao-test.mjs`, `node snapshot-test.mjs`. Dados de teste do repositório são fictícios. Dependências de teste não são necessárias para executar o site.

## Limites

Um material por trabalho. Sem reposição/ajuste auditável de estoque, formulário de custos, conciliação automática com peças/logos ou revisão dos indicadores financeiros antigos. Estoque ausente permanece desconhecido; saldo conhecido pode ficar negativo. Recuperação integral de Auth, Storage e configurações não foi ensaiada; recuperação lógica das tabelas foi testada.

PR: https://github.com/ehd1973-sys/hd3d-pedidos/pull/1 . Cópias privadas, dados de clientes e páginas configuradas para testes não fazem parte da entrega pública.
