#!/bin/bash
# Resolve todos os problemas na ordem em que eles aparecem, de fora para dentro,
# e roda o diagnóstico no final. Passe --direto para não pausar entre as etapas.
DIR="$(dirname "$0")"

for p in p3_firewall p2_config p4_processo p1_permissoes_site p5_permissoes_logs; do
    bash "$DIR/$p.sh" "$@" || exit 1
done

bash "$DIR/../scripts/diagnostico.sh"
