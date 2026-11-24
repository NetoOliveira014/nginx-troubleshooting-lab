# Gabarito

Autor: Valdomiro de Oliveira Neto

Este arquivo entrega as respostas. Use só depois de tentar.

## Resumo

| Problema | Camada | Sintoma no host | Comando que revela | Correção | Script |
| --- | --- | --- | --- | --- | --- |
| P3 | Firewall | Timeout | `iptables -L INPUT -n -v` | Remover a regra `DROP tcp dpt:80` | `p3_firewall.sh` |
| P2 | Configuração | Nginx não inicia | `nginx -t` | Devolver o `;` em `listen 80` | `p2_config.sh` |
| P4 | Processo | Conexão recusada ou resetada | `ps -C nginx`, `netstat -tlnp` | `nginx -t` e depois `nginx` | `p4_processo.sh` |
| P1 | Permissões do site | 403 Forbidden | `empresa_error.log`, `namei -l` | `chown www-data:www-data` e `chmod 755` em `public_html` | `p1_permissoes_site.sh` |
| P5 | Permissões dos logs | Nenhum para root | `ls -l /var/log/nginx` | `chown www-data:adm` e `chmod 640` nos logs do site | `p5_permissoes_logs.sh` |

## Por que esta ordem

As falhas se escondem umas atrás das outras. Cada correção faz o sintoma mudar e revela a próxima camada:

1. **Timeout** esconde todo o resto: o firewall descarta os pacotes antes de chegarem ao Nginx.
2. Sem o firewall, aparece **conexão recusada**: não há processo escutando na porta 80.
3. Ao tentar iniciar, `nginx -t` mostra o **erro de sintaxe**. Corrija a configuração antes de iniciar o processo.
4. Com o Nginx de pé, aparece o **403**: o usuário `www-data` não consegue entrar em `public_html`.
5. Com o site em 200, sobra a falha **silenciosa** dos logs, que só aparece quando se testa como um usuário que não é root.

## Pontos de aprendizado

- **DROP x REJECT:** DROP descarta sem resposta e gera timeout; REJECT responde na hora. O tipo de erro do cliente já indica a camada.
- **Linha do erro de sintaxe:** o Nginx aponta a linha onde percebeu o problema, que costuma ser a seguinte à do erro real.
- **Validar antes de iniciar:** `nginx -t` antes de `nginx`, `reload` ou `restart`, sempre.
- **Bits de diretório:** `x` permite atravessar, `r` permite listar. O Nginx precisa de `x` em todo o caminho até o arquivo.
- **Testar como root esconde problemas:** root ignora permissões de arquivo. Teste com o usuário do serviço (`su -s /bin/sh www-data -c '...'`).
- **Funcionar não é estar certo:** feche o troubleshooting revisando o ambiente inteiro, não só o sintoma principal.
