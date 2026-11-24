#!/bin/bash
# Problema 3 — Porta 80 bloqueada no firewall do container
source "$(dirname "$0")/_comum.sh"

titulo "PROBLEMA 3 — FIREWALL"

etapa "1. Sintoma: o site não responde e o curl espera até desistir"
rodar_host "curl -sS -I --max-time 5 $URL"
texto "Timeout, e não recusa, indica pacote descartado em silêncio."
pausa

etapa "2. Investigação: regras da chain INPUT"
rodar "iptables -L INPUT -n -v --line-numbers"
texto "A coluna pkts mostra quantos pacotes a regra já pegou."
pausa

etapa "3. Causa"
texto "Há uma regra 'DROP tcp dpt:80'. DROP descarta sem responder, por isso o"
texto "cliente fica esperando. Um REJECT responderia na hora."
pausa

etapa "4. Correção: remover a regra (todas as cópias, se houver mais de uma)"
rodar "while iptables -C INPUT -p tcp --dport 80 -j DROP 2>/dev/null; do iptables -D INPUT -p tcp --dport 80 -j DROP; done"
pausa

etapa "5. Verificação"
rodar "iptables -L INPUT -n"
rodar_host "curl -sS -I --max-time 5 $URL"
texto "Agora o erro deve mudar (por exemplo, para recusa ou 403): é a próxima camada aparecendo."
