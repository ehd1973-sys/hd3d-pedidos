# Aceite técnico — Fase 1, v1.0.0

Data: 05/11/2026. Estado: implementação, homologação, instalação e publicação em produção concluídas após aprovação explícita do responsável. Conferência posterior em `PUBLICACAO-FASE1.md`.

| Critério da auditoria | Resultado |
|---|---|
| Conferir esquema, RLS, relações, funções e permissões existentes | Inspecionados e preservados no pacote privado |
| Backup validado de tabelas e arquivos | Cinco tabelas recuperadas localmente; seis anexos conferidos por tamanho/MD5; SHA-256 registrado |
| Branch e ambiente separado | Branch evolucao/fase1-fdm-2026-11-05; projeto HD3D Homologacao |
| Migração aditiva e retorno documentado | Cinco tabelas novas; telas/API antigas preservadas; retorno da interface e rollback destrutivo separados |
| Impressoras e materiais | Cadastros, estados iniciais da auditoria e referências financeiras protegidas |
| Trabalho vinculado ao pedido | Equipamento, material, estado, início/fim, tempo do fatiador, massas, motivo de falha e observações |
| Sem medidas inventadas | Ausência exibida como Não medido; zero somente explícito |
| Validações | Datas, massas, equipamento ativo, material ativo, pedido cancelado, motivo de falha e acesso |
| Consumo único e estorno auditável | Repetição local e concorrência com duas conexões no Supabase; uma saída e uma compensação |
| Peças/logos preservados | Nenhum lançamento automático; contagem antiga não duplicada |
| Inclusão, edição e persistência | Fluxo real com master e recarregamento; estorno confirmado/cancelado pela interface |
| Permissões | Testadas no servidor como authenticated; funções e custos protegidos; exportação exclusiva de master ativo |
| Cálculo e celular | Duração real, energia estimada só A1/PLA; inspeção em 390 × 844 |
| Cópia dos novos dados | Exportação das dez tabelas pela interface e recuperação local do arquivo baixado; conteúdo e datas comparados |
| Revisão e entrega | PR #1, manual, roteiro de implantação, scripts e pacote versionado |

## Verificações locais finais

`test.mjs`, `ui-test.mjs`, `homologacao-test.mjs`, `snapshot-test.mjs` e recuperação do JSON baixado de homologação. Testes adicionais de recuperação da origem e da correção de TRUNCATE executados na cópia privada.

## Limites informados

Um material por trabalho; sem integração automática com quantidade, reposição auditável ou bloqueio por saldo; edição financeira administrativa; indicadores antigos mantidos. Os papéis foram testados no servidor, sem logins independentes de cada perfil na interface. Auth/senhas, anexos binários e configuração integral Supabase exigem procedimento próprio; sua recuperação integral não foi testada.

A aprovação final foi recebida e o PR #1 foi integrado em main no commit 1568bf8. Publicação GitHub Pages concluída; login existente, novas telas e exportação conferidos no endereço oficial. A cópia das dez tabelas baixada de produção foi recuperada localmente e as cinco tabelas antigas foram comparadas com o snapshot anterior à instalação, sem diferenças de conteúdo. Nenhum trabalho fictício foi criado em produção.
