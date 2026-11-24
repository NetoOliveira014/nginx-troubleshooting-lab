#!/bin/bash
# Problema 4 — Processo do Nginx encerrado
source "$(dirname "$0")/_comum.sh"

titulo "PROBLEMA 4 — PROCESSO"

etapa "1. Sintoma: conexão recusada ou resetada"
rodar_host "curl -sS -I --max-time 5 $URL"
texto "O pacote chega, mas ninguém está escutando na porta."
pausa

etapa "2. Investigação: existe processo? alguém escuta na porta 80?"
rodar "ps -C nginx -o pid,user,args || echo '(nenhum processo nginx)'"
rodar "netstat -tlnp"
pausa

etapa "3. Causa"
texto "O processo master foi encerrado e os workers morreram junto."
texto "O container continua de pé porque o entrypoint o segura com 'tail -f /dev/null'."
pausa

etapa "4. Correção: validar a configuração ANTES de iniciar"
if ! docker exec "$C" nginx -t -q 2>/dev/null; then
    rodar "nginx -t"
    texto "A configuração está inválida: rode solucao/p2_config.sh antes e volte aqui."
    exit 1
fi
rodar "nginx -t && (pgrep -x nginx >/dev/null || nginx)"
pausa

etapa "5. Verificação"
rodar "netstat -tlnp | grep ':80 '"
rodar_host "curl -sS -I --max-time 5 $URL"
