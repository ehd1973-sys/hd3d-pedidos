# HD3D na VPS — 16/11/2026

Endereço principal: https://hd3d.otimodespachante.com.br/

O banco, o login, os anexos e a função de gestão de usuários passam a usar a VPS existente. O endereço do GitHub Pages encaminha para o endereço principal. A configuração pública contém somente a chave `anon`; senhas e chaves administrativas não pertencem ao repositório.

## Validação da migração

- Cópia das 17 tabelas públicas, usuários e identidades; comparação de conteúdo e contagens entre origem e destino.
- Seis anexos conferidos, transferidos pelo Storage API e testados por links temporários autenticados. Regras de acesso do Storage transferidas separadamente do dump padrão.
- Login, pedidos e abertura/download de anexos conferidos pelo responsável.
- Estoque, custos, falta de saldo, idempotência, estorno, cadastro/retirada de insumos e baixa/estorno FDM testados em transação revertida.
- Exportação v2 e leitura da gestão de usuários verificadas. Acesso anônimo aos pedidos bloqueado.
- Gmail configurado com senha de app; recebimento da recuperação de senha confirmado pelo responsável.
- Backup operacional restaurado em banco isolado; conteúdo das 17 tabelas e seis anexos conferido.

## Operação

Os serviços executam em Docker Compose na VPS, com volumes persistentes, limites de memória e reinício automático. As rotas HTTPS usam o proxy existente do Coolify. A definição Compose é mantida na VPS; ela não é um recurso importado para a gestão de serviços do painel Coolify.

Há backup diário do banco, anexos e configuração privada na VPS, por volta de 02h30 de Brasília. A VPS já tem backup semanal do provedor. Cópias privadas da implantação foram guardadas também fora da VPS. O backup diário local não deve ser confundido com cópia diária externa.

A verificação do GitHub passa a testar site e autenticação da VPS a cada seis horas. Ela não mantém o banco antigo ativo e não substitui os backups.

## Origem e retorno

A origem é preservada com bloqueio de novas gravações após a conferência final. Não reativar gravações nem apontar usuários de volta à origem sem reconciliar os lançamentos feitos na VPS após a troca. As instruções de implantação anteriores neste repositório são históricas e não devem ser repetidas no projeto antigo.

Detalhes administrativos, senhas, backups de dados e configuração privada permanecem fora deste repositório público.
