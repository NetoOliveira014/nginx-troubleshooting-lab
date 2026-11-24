#!/bin/bash
# Problema 2 — Erro de sintaxe no virtual host
source "$(dirname "$0")/_comum.sh"

titulo "PROBLEMA 2 — CONFIGURAÇÃO"

etapa "1. Sintoma: a validação da configuração falha"
rodar "nginx -t"
texto "A mensagem aponta arquivo e linha. O erro costuma estar na linha ANTERIOR."
pausa

etapa "2. Investigação: abrir o arquivo com números de linha"
rodar "ls -l /etc/nginx/sites-enabled/"
rodar "cat -n /etc/nginx/sites-available/empresa"
texto "sites-enabled/empresa é só um link para sites-available/empresa."
pausa

etapa "3. Causa"
texto "Falta o ';' em 'listen 80'. Sem ele, o Nginx lê 'listen 80 server_name ...'"
texto "como uma diretiva só e reclama de server_name como parâmetro inválido."
pausa

etapa "4. Correção: devolver o ';' ao final da linha"
rodar "sed -i -E 's/^([[:space:]]*listen 80)[[:space:]]*\$/\1;/' /etc/nginx/sites-available/empresa"
pausa

etapa "5. Verificação"
rodar "nginx -t"
texto "Com 'test is successful', o Nginx já pode ser iniciado (problema 4)."
