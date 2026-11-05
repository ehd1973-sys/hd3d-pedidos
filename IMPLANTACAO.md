# Instalação da Fase 1

Versão 1.0.0 instalada no projeto HD3D Pedidos e publicada em 05/11/2026, após autorização explícita do responsável. A sequência abaixo documenta a instalação já realizada. Não repetir a migração na origem. Resultado e verificação em `PUBLICACAO-FASE1.md`.

## Preparação

- Revisar o PR #1, incluindo o complemento de exportação.
- Fazer cópia atualizada das cinco tabelas, anexos e estrutura. O snapshot privado de 05/11 não inclui alterações posteriores à coleta.
- Conferir login e função de usuários existentes. Não copiar fixtures ou configuração de homologação para produção.
- Esta fase não atende processos que exijam vários materiais por trabalho ou bloqueio por estoque insuficiente.

## Ordem

1. Após revisão, aplicar `seguranca-corrigir-truncate.sql` no projeto HD3D Pedidos. Revoga somente TRUNCATE de anon/authenticated nas cinco tabelas antigas, preservando registros e permissões usuais. Excesso confirmado localmente; exploração pelo REST público não foi demonstrada.
2. Aplicar `fase1.sql` uma vez, como postgres. Conflito de nomes exige revisão; não apagar tabelas para forçar instalação.
3. Aplicar `fase1-fechamento.sql`.
4. Publicar juntos `index.html` e `fdm.js` aprovados, depois da migração. Conferir que a configuração aponta ao projeto de produção.
5. Conferir login, telas antigas, impressoras/materiais, RLS das dez tabelas e exportação. Teste operacional em produção exige pedido de teste autorizado e rastreabilidade; não criar histórico real fictício.
6. Registrar commit e evidência de funcionamento. Atualizar o estado deste documento somente depois de verificar a implantação.

## Retorno

Falha antes de confirmar a migração reverte sua transação. Para problema na interface, restaurar o index.html anterior, sem carregar fdm.js. Preservar tabelas novas e registros para análise; manter a revogação de TRUNCATE.

`rollback-fase1.sql` elimina os dados novos permanentemente. Usar somente após exportação verificada e autorização específica de exclusão. Retornar a interface antiga não exige apagar o módulo.
