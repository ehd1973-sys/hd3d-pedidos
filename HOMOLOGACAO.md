# HD3D — Resultados da homologação da Fase 1

Data: 05/11/2026. Projeto separado: HD3D Homologacao (bpvlryctabjhfiipckhj). Este relatório registra os testes anteriores à publicação. A instalação posterior em produção foi autorizada e concluída na mesma data; ver `PUBLICACAO-FASE1.md`.

## Verificado no Supabase e navegador

- Instalação da base mínima e da migração FDM concluída com sucesso.
- RLS ativo nas dez tabelas; políticas conferidas por consulta.
- Usuário criado pelo responsável; perfil master liberado mediante autorização específica.
- Login real pela página local, carregamento das impressoras e materiais.
- Inclusão de impressão fictícia, persistência após recarregamento e encerramento pela interface.
- Trabalho PLA: 60 minutos, 10 g de peça + 2 g de purga; consumo registrado de 12 g.
- Trabalho PETG: 30 minutos, 5 g de peça + 1 g de perda; consumo registrado de 6 g.
- Estoque inicial ausente preservado como “Não medido”.
- Estorno repetido do trabalho PLA via função autenticada: duas movimentações preservadas, saldo líquido 0 g.
- Estorno do trabalho PETG pela interface: cancelar não alterou o registro; confirmar concluiu a compensação.
- Confirmacão nativa foi substituída por diálogo dentro da aplicação após falha do controle automático do navegador.
- Pedido continuou Aprovado e produção 0/10, sem duplicar peças/logos.
- Inspeção visual em 390 × 844: lista responsiva legível. Duração e estimativa de energia agrupadas para leitura em celular.
- Regras de leitor, operador, financeiro e inativo verificadas no Supabase com papel authenticated e claims do usuário de teste, em uma transação revertida. Leitor não grava nem recebe custos; operador grava/encerra/estorna sem cadastrar impressora ou receber custos; financeiro recebe custos e não estorna; inativo não recebe dados FDM. Perfil master original confirmado preservado no final. Isso testa RLS no servidor, sem equivaler a logins independentes de cada perfil.
- Duas conexões PostgreSQL distintas finalizaram simultaneamente a mesma impressão de 3 g. A primeira manteve o bloqueio por 20 segundos; a segunda aguardou. Resultado: apenas uma saída, 3 g, nenhuma alteração na produção de peças.
- Duas conexões distintas estornaram simultaneamente essa impressão. Resultado final: uma saída, um estorno, saldo líquido 0 g; três registros fictícios de impressão preservados em homologação.

## Testes locais

node test.mjs: restauração, migração, validações, permissões, custos protegidos, idempotência de encerramento/estorno, usuário operacional, perfil inativo, pedido cancelado e rollback.

node ui-test.mjs: navegação, campos sem medidas fictícias, escape de texto e validação de encerramento.

node homologacao-test.mjs: base nova, recusa de reinstalação, RLS das dez tabelas e página de homologação sem configuração de produção.

## Fechamento da versão 1.0.0

- Complemento `fase1-fechamento.sql` instalado com sucesso na homologação.
- Exportação pela interface com login real gerou JSON das dez tabelas. O arquivo baixado foi restaurado em banco local separado e comparado integralmente: 1 perfil, 1 pedido, 3 equipamentos, 3 materiais, 6 referências financeiras, 3 impressões e 6 movimentos. Despesas, custos de pedidos e produção estavam vazios nesse ambiente de testes.
- Datas e estados foram preservados, gatilho reativado e numeração conferida. Destino ocupado é recusado, sem sobrescrever dados.
- Permissão de exportação verificada no Supabase: leitor, operador, financeiro e inativo recusados; master ativo exportou. Mudanças temporárias dos perfis foram revertidas.
- Exportação original ampliada no pacote privado: estrutura detalhada, grants, funções SQL, sequência, metadados de Auth/Storage, função de borda e código original. Cinco tabelas originais recuperadas localmente e seis anexos íntegros. Senhas e configuração integral dos serviços não compõem esse pacote.
- Correção separada de TRUNCATE testada localmente, mantendo SELECT; posteriormente aplicada à origem na instalação autorizada. Não foi demonstrada exploração pelo REST público.
- Novos testes: `node snapshot-test.mjs` e `node verificar-copia.mjs caminho-da-copia.json`.

## Condições e limites da implantação

- Cobertura adicional opcional: telas e sessão HTTP de cada perfil com logins independentes. As regras de servidor já passaram no Supabase, e o fluxo de interface foi validado com master.
- Recuperação integral de Auth, Storage e configurações dos serviços gerenciados não foi ensaiada; o teste de restauração é lógico, das tabelas. Esse limite é explícito no manual.
- Revisão consolidada aprovada pelo responsável. Cópia atualizada das cinco tabelas e seis anexos conferida antes da mudança; instalador exato validado localmente sobre essa cópia. Após a publicação, a cópia das dez tabelas baixada de produção foi recuperada e o conteúdo antigo foi comparado com o snapshot anterior, sem diferenças.

## Limitações de escopo

Um material por trabalho. Sem reposição/ajuste auditável de estoque, formulário de custos ou revisão dos indicadores financeiros antigos. O estoque conhecido não bloqueia consumo maior que o saldo. A nova exportação cobre as dez tabelas, mas não é backup integral dos serviços Supabase. Não usar esta fase como cálculo de lucro líquido.

Os dados de teste permanecem exclusivamente em homologação e estão identificados como fictícios.
