#!/bin/bash
# Problema 5 — Logs do site sem permissão de leitura
source "$(dirname "$0")/_comum.sh"

titulo "PROBLEMA 5 — PERMISSÕES DOS LOGS"

etapa "1. Sintoma: nenhum, se você testar como root"
rodar "tail -n 1 /var/log/nginx/empresa_error.log"
texto "Como root funciona: root ignora permissões de arquivo."
pausa

etapa "2. Investigação: comparar permissões e testar como www-data"
rodar "ls -l /var/log/nginx/"
rodar "su -s /bin/sh www-data -c 'tail -n 1 /var/log/nginx/empresa_error.log' || true"
pausa

etapa "3. Causa"
texto "empresa_access.log e empresa_error.log estão com permissão 000 (----------)."
texto "O Nginx continua gravando porque quem abre os logs é o processo master, como root."
texto "Quem não é root (grupo adm, monitoramento, logrotate) fica sem acesso."
pausa

etapa "4. Correção: voltar ao que o Dockerfile define (www-data:adm, 640)"
rodar "chown www-data:adm /var/log/nginx/empresa_access.log /var/log/nginx/empresa_error.log && chmod 640 /var/log/nginx/empresa_access.log /var/log/nginx/empresa_error.log"
pausa

etapa "5. Verificação"
rodar "ls -l /var/log/nginx/"
rodar "su -s /bin/sh www-data -c 'tail -n 1 /var/log/nginx/empresa_error.log' && echo 'leitura como www-data: ok'"
