# Instalação do incremento de insumos — v1.1

Pré-requisito: Fase 1 e seu complemento de exportação já instalados. Não reaplicar fase1.sql. Instalar primeiro em ambiente separado e revisar o resultado.

1. Fazer cópia atualizada das dez tabelas, estrutura e anexos da origem. Guardar index.html/fdm.js e definições das funções existentes. Validar a recuperação da cópia.
2. Conferir que os sete nomes novos não conflitam com objetos existentes e que as funções atuais correspondem à Fase 1.
3. Aplicar insumos.sql uma única vez, como postgres. Cria sete tabelas e integra as funções de encerramento/estorno ao novo estoque. Mantém os lançamentos anteriores, sem inventar preços, saldo desconhecido ou custo histórico.
4. Publicar index.html, fdm.js e insumos.js da mesma revisão, além do conversor/documentação atualizados. Banco deve ser instalado antes das telas.
5. Conferir login, 17 tabelas com RLS, ausência de escrita direta no estoque e acesso financeiro restrito. Não copiar dados fictícios da homologação para produção.
6. O responsável deve informar contagens e custos reais antes de novos consumos. Compras, planejamento, consumo e previsão aplicada são feitos pelas telas descritas em MANUAL-INSUMOS.md.
7. Registrar o resultado da publicação e da conferência em relatório separado. A correção não deve ser anunciada como instalada antes disso.

## Retorno

Se a migração falhar, a transação reverte. Após instalação confirmada, preservar os dados e usar correção para frente; não apagar tabelas/movimentos para desfazer a publicação. A volta de uma tela antiga não basta: os encerramentos FDM passaram a conferir saldo e custo. As funções da Fase 1 foram preservadas internamente com acesso direto revogado e só podem ser restauradas em uma mudança revisada junto do estado do estoque.

## Validação realizada

Suíte local cobre compra ponderada, consumo conjunto de vários itens, rollback por saldo insuficiente, custo histórico, estorno idempotente, integração FDM, permissões, interface e recuperação exata das 17 tabelas, inclusive precisão decimal. Dados de teste são fictícios.

Homologação real: contagem pela interface; composição com filamento + argola + correntinha; aplicação da previsão ao custo do pedido; consumo manual de ferragens e automático de filamento; reposição com preço novo preservando custo histórico; perfis no servidor; duas conexões disputando o mesmo saldo. A segunda baixa foi recusada após aguardar a primeira, com conexões distintas. Um consumo e um estorno preservados no teste, sem saldo duplicado.
