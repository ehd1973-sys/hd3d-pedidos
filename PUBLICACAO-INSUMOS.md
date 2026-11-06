# Publicação — Insumos e custos v1.1

Instalação no projeto HD3D Pedidos e publicação no GitHub Pages concluídas em 05/11/2026, após o responsável autorizar a revisão nº 2. Site: https://ehd1973-sys.github.io/hd3d-pedidos/ . Revisão integrada: https://github.com/ehd1973-sys/hd3d-pedidos/pull/2 . Código aprovado: be254f2f517522576ddd85fa91cd048e73b05c98; integração: 0255f46e0d2e557fdac8dc89a3ca232f98e99cfc.

A publicação do código foi concluída com sucesso na execução 42136177303, em 46 segundos. Os três arquivos index.html, fdm.js e insumos.js responderam HTTP 200 e tiveram conteúdo comparado com a revisão aprovada, normalizando apenas finais de linha Windows/Linux. A sessão existente carregou a nova tela de estoque no site em uso.

Antes de instalar, foi feita cópia atualizada das dez tabelas e da estrutura. A recuperação foi ensaiada e comparada. Os seis anexos foram reconferidos por tamanho e MD5; as definições anteriores das funções de encerramento, estorno e exportação foram conferidas. A instalação verificou a cópia antes de executar e preservou o conteúdo das dez tabelas existentes na mesma transação.

Após instalar: 17 tabelas com RLS; sem permissão de truncar para anon/authenticated; sem atualização direta do novo estoque; funções auxiliares e versões antigas sem acesso dos usuários; operações que contêm custos sem leitura direta. Apenas os três filamentos já existentes foram integrados. Nenhuma ferragem, saldo físico ou custo médio foi presumido, e nenhum dado fictício foi copiado para produção. A cópia das 17 tabelas após a instalação também foi restaurada e comparada.

## Começar a usar

1. Em Insumos e estoque, cadastre os produtos utilizados e suas variantes. O cadastro é livre.
2. Informe a contagem e o custo reais de cada item, inclusive filamentos, antes de novos consumos ou encerramentos de impressão.
3. Em Custo de produção, escolha o pedido e os itens consumidos no lote. Não é obrigatório salvar uma composição prévia. O administrador também pode cadastrar um novo insumo durante esse preenchimento.
4. Para erros de cadastro, use Editar cadastro ou Excluir do catálogo. A retirada é reversível e preserva o histórico; saldo físico e vínculos abertos precisam ser corrigidos antes. Erros de consumo são corrigidos por estorno.

Manual: [MANUAL-INSUMOS.md](MANUAL-INSUMOS.md). Cópias privadas, dados de clientes, anexos e configurações de sessão não são publicados neste repositório. A recuperação lógica de tabelas foi testada; não substitui recuperação integral dos serviços de autenticação e armazenamento.