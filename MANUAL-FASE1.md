# Operação da Fase 1

## Impressoras e materiais

Use o acesso habitual. Em Impressoras, o administrador cadastra equipamento e altera seu estado. Ative somente equipamento disponível. QIDI Q2 e Kobra X começam aguardando ativação.

Em Materiais, o administrador cadastra tipo, fabricante, cor e estoque inicial quando medido. Campo vazio significa desconhecido; zero é uma medida. Cadastros novos não recebem preço presumido. Alterações financeiras ainda são administrativas no banco.

## Apontar trabalho

1. Em Impressões, clique em Nova impressão. Exige permissão Produção.
2. Escolha pedido, impressora ativa e material. Use um registro por trabalho com um material; não simule vários materiais com registros que dupliquem a duração.
3. Informe início/término reais, tempo do fatiador separado, peso das peças, purga e desperdício, em gramas. Deixe medidas desconhecidas vazias enquanto aberto.
4. Salve como Planejada ou Imprimindo. Para alterar, use Editar / encerrar.
5. Conclusão ou falha exige início, término e as três massas. Falha exige motivo. Cancelamento também exige as três massas, com zero somente quando medido.
6. Encerramento registra consumo uma vez. Lance as peças/logos na tela Produção; o apontamento FDM não faz isso automaticamente.

Horários seguem o fuso do aparelho. Término não antecede início; massas e tempos não podem ser negativos. Tempo do fatiador não substitui duração real.

## Corrigir consumo

Use Estornar consumo e confirme. Impressão e saída original permanecem; entrada compensatória devolve o consumo. Cadastre o trabalho correto em seguida. Repetir não duplica devolução. Falha real consumiu material: registre a perda no encerramento e não estorne somente porque a peça falhou.

## Cópia de dados

Como master ativo, abra Backup e escolha Exportar dados da Fase 1. O JSON contém as dez tabelas, incluindo perfis, custos e movimentações. Confira o download e guarde em local privado. O exportador antigo continua disponível, mas não inclui o módulo novo.

O arquivo novo não é aceito pelo importador antigo; não altere seu identificador para tentar importá-lo. Ele não contém anexos binários ou senhas/sessões/configurações de Auth. Mantenha cópia separada dos arquivos, código e configuração do projeto.

## Recuperação administrativa

1. Crie destino separado e vazio com os serviços necessários. Preserve UUIDs de Auth ou planeje seu mapeamento. Não insira usuários manualmente nas tabelas internas de Auth.
2. Recupere a estrutura original, depois aplique `fase1-estrutura-recuperacao.sql` e `fase1-fechamento.sql`. Não use aqui a migração com cadastros iniciais: a cópia já contém esses registros.
3. Execute `node snapshot-para-sql.mjs copia.json recuperar.sql`. Gera arquivo local, sem alterar bancos. Não publique nem envie esse SQL ao GitHub.
4. Confira o destino e execute como administrador. O SQL bloqueia as tabelas na transação, recusa destino com registros, preserva datas e reativa o gatilho antes de confirmar. Erros revertem a transação.
5. Recupere os arquivos pelo Storage mantendo caminhos, suas políticas e a função de usuários/configuração por procedimento administrativo.
6. Valide login, permissões, dados, anexos e numeração antes de liberar acesso. Os testes entregues comprovam recuperação das tabelas; não substituem ensaio integral dos serviços gerenciados.

O pacote privado da origem está separado da entrega pública e contém roteiro próprio.
