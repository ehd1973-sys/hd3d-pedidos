# HD3D — Fase 1 para revisão

Versão local de desenvolvimento, 05/11/2026. Não instalada no Supabase nem publicada.

## Conteúdo

- index.html: aplicação existente com carregamento de fdm.js.
- fdm.js: telas Impressoras, Materiais e Impressões, vinculadas aos pedidos.
- fase1.sql: migração aditiva para homologação.
- rollback-fase1.sql: remoção do módulo novo; destrutiva para seus registros, nunca executada automaticamente.
- test.mjs e ui-test.mjs: testes de restauração, regras do banco e interface.
- restore-fixture.sql: reconstrução parcial da estrutura original para testes locais; não é dump completo do Supabase.

## Regras implementadas

Master cadastra impressoras e materiais e muda o estado das impressoras. Usuários ativos consultam o módulo; a permissão Produção permite apontar e encerrar impressões. Custos ficam em tabela separada protegida por RLS financeiro. Somente master pode alterar as referências financeiras no banco; sua edição ainda não tem formulário.

Encerramento registra uma saída de material em transação; repetição é idempotente. Estorno mantém a saída original e registra entrada compensatória uma única vez. Registros encerrados não podem ser editados pelos usuários. Estoque inicial ausente continua “Não medido”; o saldo conhecido não impede consumo maior que o estoque. Reposição e ajustes auditáveis serão uma etapa posterior.

A1 ativa; QIDI Q2 e Kobra X aguardando ativação. PLA/PETG/TPU são referências genéricas, sem cor, fabricante ou estoque inventados. Valores financeiros e vida útil de 48 meses vêm da auditoria; residual não definido. Cadastros novos não recebem custo ou estoque presumido.

Duração é calculada de início e término; tempo do fatiador é separado. Nenhum registro histórico foi criado. Energia só aparece como estimativa para IMP-001 com PLA e duração registrada, usando 95 W e R$0,89/kWh. Não representa medição nem custo líquido. Registros estornados permanecem na lista e ficam fora do total de horas por impressora.

O módulo não lança peças/logos nem altera os cálculos financeiros antigos. Usa um material por trabalho; impressões com vários materiais exigem evolução do modelo antes do uso. Não usar apontamentos separados para simular múltiplos materiais se isso duplicar duração.

## Validação realizada

Restauração dos dados das cinco tabelas em PostgreSQL embarcado PGlite, com comparação completa do conteúdo. Seis anexos conferidos por tamanho e MD5; SHA-256 registrado no pacote de backup. Testes de migração, massa negativa, impressora inativa, permissões, proteção dos custos, encerramento e estorno repetidos, proibição de movimento direto e preservação da contagem de produção. Testes da interface em DOM: navegação, formulário, medidas ausentes, escape de texto e validação antes de encerrar.

Limites: não é teste de recuperação integral do projeto Supabase. Usuários Auth/senhas, gatilhos, grants originais, configurações e funções de borda ainda não foram exportados integralmente. Os testes locais usam uma estrutura reconstruída do inventário; faltam homologação real, persistência por recarregamento, teste concorrente em sessões separadas e inspeção visual em celular. Não há autorização de publicação nesta versão.

## Como homologar

1. Criar ambiente separado compatível com o esquema e as funções existentes; manter as credenciais de produção fora dos testes.
2. Aplicar fase1.sql nesse ambiente como proprietário postgres e conferir grants e políticas padrão. As funções e o gatilho foram testados com proprietário postgres.
3. Servir index.html e fdm.js na mesma pasta por HTTP e conectar exclusivamente ao ambiente de homologação.
4. Testar com master, operador com Produção, leitor, financeiro e perfil inativo. Conferir recarregamento, falha, estorno, concorrência e largura de celular.
5. Revisar e aprovar antes de aplicar migração e publicar no sistema em uso.

Para repetir os testes locais: npm ci, node test.mjs, node ui-test.mjs. Por padrão são usados apenas dados fictícios de fixture-teste.json. Para validar novamente a cópia privada, definir HD3D_TEST_BACKUP com o caminho de dados.json. Não incluir dados privados em Git ou em hospedagem pública.

homologacao-base.sql reconstrói a base mínima existente com políticas e um pedido fictício em um projeto Supabase novo. Recusa instalação quando pedidos ou perfis já existem. Não substitui o dump completo do ambiente original nem inclui usuários Auth, arquivos ou função de borda usuarios.

homologacao.html vem sem configuração de produção: solicita URL e chave pública do novo projeto. Não usar index.html para a primeira configuração do ambiente de testes. Cadastro de usuários Auth e vinculação dos perfis de teste devem ser feitos exclusivamente no ambiente separado.

## Situação do GitHub

A branch evolucao/fase1-fdm-2026-11-05 foi criada pelo navegador e recebeu a versão inicial no commit c6a620c. As melhorias de homologação posteriores estão locais até o próximo envio. Nenhum PR foi criado, SQL de produção aplicado ou site publicado.
