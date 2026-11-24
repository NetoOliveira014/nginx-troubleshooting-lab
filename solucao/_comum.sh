#!/bin/bash
# Funções compartilhadas pelos scripts de resolução.
# Cada script segue o mesmo roteiro: sintoma, investigação, causa, correção, verificação.
#
# Por padrão o script pausa entre as etapas para você ler a saída.
# Use --direto para rodar sem pausas.

C=lab-nginx
URL=http://localhost:8080
DIRETO=0
[ "$1" = "--direto" ] && DIRETO=1

if ! docker ps --format '{{.Names}}' | grep -qx "$C"; then
    echo "O container $C não está rodando. Rode scripts/reset.sh primeiro."
    exit 1
fi

titulo() {
    echo ""
    echo "========================================="
    echo "  $*"
    echo "========================================="
}

etapa() {
    echo ""
    echo "▶ $*"
}

texto() {
    echo "  $*"
}

# Mostra e executa um comando dentro do container
rodar() {
    echo "  (container) \$ $1"
    docker exec "$C" bash -c "$1" 2>&1 | sed 's/^/    /'
}

# Mostra e executa um comando no host
rodar_host() {
    echo "  (host) \$ $1"
    bash -c "$1" 2>&1 | sed 's/^/    /'
}

pausa() {
    if [ "$DIRETO" -eq 0 ] && [ -t 0 ]; then
        read -r -p "  [Enter para continuar] " _
    fi
}
