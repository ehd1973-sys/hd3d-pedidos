# Publicação da Fase 1 v1.0.0

Concluída em 05/11/2026 após autorização explícita do responsável para cópia atualizada, correção de permissões, migração, integração do PR e publicação.

Sistema: https://ehd1973-sys.github.io/hd3d-pedidos/

PR integrado: https://github.com/ehd1973-sys/hd3d-pedidos/pull/1

Código aprovado: `dfc3a3d7d17a72a1d04d31358f553e33bd65d461`. Integração em main: `1568bf801bcf7e849b209d6bd0e80a9c9fbd45a5`.

Publicação do código concluída com sucesso: https://github.com/ehd1973-sys/hd3d-pedidos/actions/runs/42087721653

## Conferência

- Cópia atualizada dos dados e estrutura antes da instalação; anexos reconferidos por tamanho/MD5 e pacote privado com SHA-256. Recuperação local da cópia atual aprovada.
- Instalador exato ensaiado localmente. Instalação no banco em uma única transação, com bloqueio breve das tabelas antigas e comparação de seu conteúdo antes/depois dentro da transação.
- Correção restrita de TRUNCATE, cinco tabelas novas, referências iniciais e função de exportação instaladas.
- Conferência posterior: dez tabelas com RLS; anon/authenticated sem TRUNCATE; funções de encerramento, estorno e exportação sem execução anônima; proprietário postgres nas funções FDM.
- Login existente preservado. Impressoras, materiais, formulário de apontamento e exportação conferidos no site oficial.
- Cópia das dez tabelas baixada pelo site de produção recuperada em banco local separado, com conteúdo, datas, gatilho e numeração conferidos. As cinco tabelas antigas têm conteúdo igual ao snapshot anterior à instalação.
- Nenhuma impressão ou movimentação fictícia foi criada em produção. A1 ativa; demais impressoras aguardando ativação; medidas desconhecidas preservadas.

Cópias privadas anteriores e posteriores foram guardadas localmente, fora deste repositório. Não há senhas ou dados de clientes neste registro de publicação. A documentação de fechamento é posterior à integração e não modifica o código da aplicação.

## Uso e limites

Consultar `MANUAL-FASE1.md`. A exportação inclui as tabelas, sem anexos binários, senhas ou configuração integral dos serviços Supabase. Recuperação integral desses serviços não foi ensaiada. Um material por trabalho; sem integração automática com quantidades ou reposição auditável. Os testes operacionais de gravação/estorno foram executados em homologação; a conferência de produção não criou trabalhos de teste.
