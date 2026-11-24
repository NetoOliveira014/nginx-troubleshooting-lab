#!/bin/bash
echo ""
echo "========================================="
echo "  RESETANDO LABORATÓRIO NGINX"
echo "========================================="
echo ""

# Funciona em qualquer pasta onde o lab tenha sido copiado ou clonado
cd "$(dirname "$0")/.." || exit 1
docker compose down
docker rmi lab-nginx-web -f 2>/dev/null
docker compose up -d --build
sleep 3

echo ""
echo "========================================="
echo "  LABORATÓRIO RESTAURADO!"
echo "  Teste: curl -I http://localhost:8080"
echo "========================================="
echo ""
