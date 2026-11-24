#!/bin/bash
# Uso:
#   ./inject_problems.sh          injeta os 5 problemas
#   ./inject_problems.sh 1 3      injeta só os problemas indicados (1 a 5)

if ! docker ps --format '{{.Names}}' | grep -qx lab-nginx; then
    echo "O container lab-nginx não está rodando. Rode scripts/reset.sh primeiro."
    exit 1
fi

if [ $# -eq 0 ]; then
    set -- 1 2 3 4 5
fi

echo ""
echo "========================================="
echo "  INJETANDO PROBLEMAS — LAB NGINX"
echo "========================================="
echo ""

for p in "$@"; do
    case "$p" in
        1)
            # PROBLEMA 1 — Permissão incorreta no diretório do site
            docker exec lab-nginx chown root:root /var/www/empresa/public_html
            docker exec lab-nginx chmod 700 /var/www/empresa/public_html
            echo "❌ [PROBLEMA 1] Permissão do diretório alterada para root:root 700"
            ;;
        2)
            # PROBLEMA 2 — Erro de sintaxe na configuração do Nginx
            docker exec lab-nginx sed -i 's/listen 80;/listen 80/' \
                /etc/nginx/sites-available/empresa
            echo "❌ [PROBLEMA 2] Erro de sintaxe injetado no virtual host"
            ;;
        3)
            # PROBLEMA 3 — Bloqueio de porta via iptables
            docker exec lab-nginx iptables -F INPUT
            docker exec lab-nginx iptables -A INPUT -p tcp --dport 80 -j DROP
            echo "❌ [PROBLEMA 3] Porta 80 bloqueada via iptables"
            ;;
        4)
            # PROBLEMA 4 — Matar o processo do Nginx
            docker exec lab-nginx pkill -f "nginx: master"
            echo "❌ [PROBLEMA 4] Processo Nginx encerrado"
            ;;
        5)
            # PROBLEMA 5 — Remover permissões dos logs
            docker exec lab-nginx chmod 000 /var/log/nginx/empresa_access.log
            docker exec lab-nginx chmod 000 /var/log/nginx/empresa_error.log
            echo "❌ [PROBLEMA 5] Permissões dos logs removidas"
            ;;
        *)
            echo "Problema desconhecido: $p (use números de 1 a 5)"
            exit 1
            ;;
    esac
done

echo ""
echo "========================================="
echo "  AMBIENTE COMPROMETIDO!"
echo "  Entre no container para investigar:"
echo "  docker exec -it lab-nginx bash"
echo "========================================="
echo ""
