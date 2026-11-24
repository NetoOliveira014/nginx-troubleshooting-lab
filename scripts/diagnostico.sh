#!/bin/bash
# Diagnóstico automático do lab.
#
# 1. Coleta FATOS: perguntas de sim ou não sobre o ambiente (1 = verdadeiro, 0 = falso).
# 2. Combina os fatos com REGRAS booleanas para concluir qual problema está ativo.
# 3. Compara o sintoma observado com o sintoma que as regras preveem.
#
# Uso:
#   ./diagnostico.sh             mostra só o estado de cada camada (bom para estudar)
#   ./diagnostico.sh --explicar  mostra também as regras, as causas e as correções
#
# Código de saída: soma dos problemas detectados (máscara de bits).
#   P1 = 1, P2 = 2, P3 = 4, P4 = 8, P5 = 16, container parado = 64, 0 = saudável.

C=lab-nginx
URL=http://localhost:8080
EXPLICAR=0
[ "$1" = "--explicar" ] && EXPLICAR=1

# Executa um teste e devolve 1 se ele passou, 0 se falhou
fato() { if "$@" >/dev/null 2>&1; then echo 1; else echo 0; fi; }
no_container() { docker exec "$C" bash -c "$1"; }
como_www_data() { docker exec "$C" su -s /bin/sh www-data -c "$1"; }

sim_nao() { [ "$1" -eq 1 ] && echo "verdadeiro" || echo "falso"; }

# ---------------------------------------------------------------------------
# 1. Fatos
# ---------------------------------------------------------------------------

CONTAINER_ATIVO=$(fato test "$(docker inspect -f '{{.State.Running}}' "$C" 2>/dev/null)" = true)

HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$URL")
CURL_RC=$?
HTTP_TIMEOUT=$(( CURL_RC == 28 ))
HTTP_200=$(( HTTP_CODE == 200 ))
HTTP_403=$(( HTTP_CODE == 403 ))

if [ "$CONTAINER_ATIVO" -eq 1 ]; then
    FIREWALL_BLOQUEIA=$(fato no_container "iptables -S INPUT | grep -Eq -- '--dport 80 .*-j (DROP|REJECT)'")
    NGINX_RODANDO=$(fato no_container "pgrep -x nginx")
    PORTA_80_ABERTA=$(fato no_container "netstat -tln | grep -q ':80 '")
    CONFIG_VALIDA=$(fato no_container "nginx -t -q")
    SITE_LEGIVEL=$(fato como_www_data "test -r /var/www/empresa/public_html/index.html")
    LOGS_LEGIVEIS=$(fato como_www_data "test -r /var/log/nginx/empresa_access.log && test -r /var/log/nginx/empresa_error.log")
else
    FIREWALL_BLOQUEIA=0; NGINX_RODANDO=0; PORTA_80_ABERTA=0
    CONFIG_VALIDA=0; SITE_LEGIVEL=0; LOGS_LEGIVEIS=0
fi

# ---------------------------------------------------------------------------
# 2. Regras booleanas (&& = E, || = OU, ! = NÃO)
# ---------------------------------------------------------------------------

P3=$(( CONTAINER_ATIVO && FIREWALL_BLOQUEIA ))   # firewall
P4=$(( CONTAINER_ATIVO && !NGINX_RODANDO ))      # processo
P2=$(( CONTAINER_ATIVO && !CONFIG_VALIDA ))      # configuração
P1=$(( CONTAINER_ATIVO && !SITE_LEGIVEL ))       # permissões do site
P5=$(( CONTAINER_ATIVO && !LOGS_LEGIVEIS ))      # permissões dos logs

# Regras derivadas: combinações que mudam o que fazer
NAO_SOBE=$(( P4 && P2 ))                 # nginx parado E config quebrada: não inicia
BOMBA_RELOAD=$(( NGINX_RODANDO && P2 ))  # rodando com config antiga: o próximo reload derruba
SAUDAVEL=$(( CONTAINER_ATIVO && !P1 && !P2 && !P3 && !P4 && !P5 ))

# Sintoma que as regras preveem, da camada mais externa para a mais interna
if   [ "$CONTAINER_ATIVO" -eq 0 ]; then PREVISTO="conexão recusada (container parado)"
elif [ "$P3" -eq 1 ];              then PREVISTO="timeout"
elif [ "$PORTA_80_ABERTA" -eq 0 ]; then PREVISTO="conexão recusada ou resetada"
elif [ "$P1" -eq 1 ];              then PREVISTO="HTTP 403"
else                                    PREVISTO="HTTP 200"
fi

if   [ "$HTTP_TIMEOUT" -eq 1 ]; then OBSERVADO="timeout"
elif [ "$HTTP_200" -eq 1 ];     then OBSERVADO="HTTP 200"
elif [ "$HTTP_403" -eq 1 ];     then OBSERVADO="HTTP 403"
elif [ "$HTTP_CODE" = "000" ];  then
    [ "$CONTAINER_ATIVO" -eq 0 ] && OBSERVADO="conexão recusada (container parado)" \
                                 || OBSERVADO="conexão recusada ou resetada"
else                                 OBSERVADO="HTTP $HTTP_CODE"
fi

# ---------------------------------------------------------------------------
# 3. Relatório
# ---------------------------------------------------------------------------

echo ""
echo "========================================="
echo "  DIAGNÓSTICO — LAB NGINX"
echo "========================================="
echo ""
echo "FATOS COLETADOS"
printf "  %-22s %s\n" \
    "container_ativo"   "$(sim_nao "$CONTAINER_ATIVO")" \
    "firewall_bloqueia" "$(sim_nao "$FIREWALL_BLOQUEIA")" \
    "nginx_rodando"     "$(sim_nao "$NGINX_RODANDO")" \
    "porta_80_aberta"   "$(sim_nao "$PORTA_80_ABERTA")" \
    "config_valida"     "$(sim_nao "$CONFIG_VALIDA")" \
    "site_legivel"      "$(sim_nao "$SITE_LEGIVEL")" \
    "logs_legiveis"     "$(sim_nao "$LOGS_LEGIVEIS")"
echo ""

# printf conta bytes, não letras: alinha os nomes com acento pelo tamanho em caracteres
alinhar() { printf "  %s%*s" "$1" $(( 27 - ${#1} )) ""; }

camada() {  # nome, falhou, regra, causa, correção
    if [ "$2" -eq 1 ]; then
        echo "$(alinhar "$1")FALHA"
        if [ "$EXPLICAR" -eq 1 ]; then
            echo "      regra:    $3"
            echo "      causa:    $4"
            echo "      correção: $5"
        fi
    else
        echo "$(alinhar "$1")OK"
    fi
}

echo "CAMADAS, DE FORA PARA DENTRO"
if [ "$CONTAINER_ATIVO" -eq 0 ]; then
    echo "  Container                  FALHA"
    echo "      Suba o ambiente com scripts/reset.sh. As demais camadas não podem ser testadas."
else
    camada "Firewall"             "$P3" "container_ativo E firewall_bloqueia" \
        "regra DROP na porta 80 da chain INPUT" "solucao/p3_firewall.sh"
    camada "Processo"             "$P4" "container_ativo E NÃO nginx_rodando" \
        "processo master do Nginx encerrado" "solucao/p4_processo.sh"
    camada "Configuração"         "$P2" "container_ativo E NÃO config_valida" \
        "erro de sintaxe no virtual host (nginx -t falha)" "solucao/p2_config.sh"
    camada "Permissões do site"   "$P1" "container_ativo E NÃO site_legivel" \
        "www-data não consegue ler o site" "solucao/p1_permissoes_site.sh"
    camada "Permissões dos logs"  "$P5" "container_ativo E NÃO logs_legiveis" \
        "www-data não consegue ler os logs (invisível para root)" "solucao/p5_permissoes_logs.sh"
fi
echo ""

echo "SINTOMA"
echo "  observado no host: $OBSERVADO"
echo "  previsto pelas regras: $PREVISTO"
if [ "$OBSERVADO" = "$PREVISTO" ]; then
    echo "  O sintoma confirma o diagnóstico."
else
    echo "  O sintoma NÃO bate com o diagnóstico: existe algo fora das regras. Investigue manualmente."
fi
echo ""

if [ "$EXPLICAR" -eq 1 ]; then
    [ "$NAO_SOBE" -eq 1 ] && \
        echo "ATENÇÃO: Nginx parado E configuração inválida. Corrija a configuração antes de iniciar o processo."
    [ "$BOMBA_RELOAD" -eq 1 ] && \
        echo "ATENÇÃO: Nginx rodando com configuração inválida em disco. O próximo reload ou restart vai derrubá-lo."
    [ "$P5" -eq 1 ] && [ "$SAUDAVEL" -eq 0 ] && [ "$(( P1 || P2 || P3 || P4 ))" -eq 0 ] && \
        echo "OBS.: o site funciona, mas os logs estão inacessíveis para quem não é root."
    if [ "$SAUDAVEL" -eq 0 ] && [ "$CONTAINER_ATIVO" -eq 1 ]; then
        ORDEM=""
        [ "$P3" -eq 1 ] && ORDEM="$ORDEM p3"
        [ "$P2" -eq 1 ] && ORDEM="$ORDEM p2"
        [ "$P4" -eq 1 ] && ORDEM="$ORDEM p4"
        [ "$P1" -eq 1 ] && ORDEM="$ORDEM p1"
        [ "$P5" -eq 1 ] && ORDEM="$ORDEM p5"
        echo "Ordem sugerida de correção:$ORDEM"
    fi
    echo ""
fi

if [ "$SAUDAVEL" -eq 1 ]; then
    echo "RESULTADO: ambiente saudável."
elif [ "$CONTAINER_ATIVO" -eq 0 ]; then
    echo "RESULTADO: container parado."
else
    echo "RESULTADO: $(( P1 + P2 + P3 + P4 + P5 )) problema(s) detectado(s)."
    [ "$EXPLICAR" -eq 0 ] && echo "Rode com --explicar para ver regras, causas e correções."
fi
echo ""

exit $(( P1*1 + P2*2 + P3*4 + P4*8 + P5*16 + (1 - CONTAINER_ATIVO)*64 ))
