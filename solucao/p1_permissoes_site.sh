#!/bin/bash
# Problema 1 — Diretório do site inacessível para o usuário do Nginx
source "$(dirname "$0")/_comum.sh"

titulo "PROBLEMA 1 — PERMISSÕES DO SITE"

etapa "1. Sintoma: 403 Forbidden"
rodar_host "curl -sS -I --max-time 5 $URL"
texto "Rede e processo estão bons: o problema é da aplicação. Hora de ler o log."
pausa

etapa "2. Investigação: log de erro, permissões do caminho e teste como www-data"
rodar "tail -n 5 /var/log/nginx/empresa_error.log"
rodar "namei -l /var/www/empresa/public_html/index.html"
rodar "su -s /bin/sh www-data -c 'ls /var/www/empresa/public_html' || true"
pausa

etapa "3. Causa"
texto "public_html está como root:root com permissão 700 (drwx------)."
texto "Os workers do Nginx rodam como www-data, que não consegue entrar no diretório."
texto "Para atravessar um diretório é preciso o bit x; para listar, o bit r."
pausa

etapa "4. Correção: devolver dono e permissão"
rodar "chown www-data:www-data /var/www/empresa/public_html && chmod 755 /var/www/empresa/public_html"
pausa

etapa "5. Verificação"
rodar "namei -l /var/www/empresa/public_html/index.html"
rodar_host "curl -sS -I --max-time 5 $URL"
