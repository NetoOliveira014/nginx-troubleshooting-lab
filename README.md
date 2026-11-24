# Lab de Troubleshooting de Nginx

Autor: Valdomiro de Oliveira Neto

Laboratório para treinar diagnóstico de falhas em um servidor web Linux. Um container Ubuntu 22.04 com Nginx publica o site da empresa fictícia "Empresa Segura LTDA" em `http://localhost:8080`. Um script quebra o ambiente em até 5 pontos, cada um em uma camada diferente, e o objetivo é descobrir e corrigir cada falha como em um servidor real.

## Requisitos

| Item | Versão ou condição |
| --- | --- |
| Sistema | Linux (testado no Ubuntu); macOS ou Windows com Docker Desktop devem funcionar, sem garantia |
| Docker Engine | 20.10 ou superior |
| Docker Compose | Plugin v2 (`docker compose`, sem hífen) |
| Permissão | Usuário no grupo `docker`, ou uso de `sudo` |
| Porta | 8080 livre no host |
| Rede | Acesso à internet no primeiro build (o `apt-get` baixa os pacotes) |
| Ferramentas no host | `bash` e `curl` |

Verificação rápida:

```bash
docker --version
docker compose version
curl --version
```

## Estrutura

```
lab-nginx/
├── Dockerfile               imagem Ubuntu 22.04 com Nginx e ferramentas de diagnóstico
├── docker-compose.yml       container lab-nginx, porta 8080 → 80, capacidade NET_ADMIN
├── entrypoint.sh            inicia o Nginx e mantém o container de pé
├── configs/empresa.conf     virtual host do site
├── site/index.html          página esperada quando tudo funciona
├── scripts/
│   ├── reset.sh             reconstrói o ambiente do zero
│   ├── inject_problems.sh   injeta as falhas (todas ou só as escolhidas)
│   └── diagnostico.sh       diagnóstico automático por lógica booleana
└── solucao/                 GABARITO: não abra antes de tentar
    ├── GABARITO.md
    ├── p1_ ... p5_*.sh      resolução comentada de cada problema
    └── resolver_tudo.sh     resolve tudo na ordem certa
```

A capacidade `NET_ADMIN` existe só para que o `iptables` funcione dentro do container. Ela não dá acesso ao firewall do host.

## Montagem do ambiente

1. Copie ou clone a pasta `lab-nginx` para qualquer lugar da sua máquina e entre nela:

   ```bash
   cd lab-nginx
   ```

2. Dê permissão de execução aos scripts:

   ```bash
   chmod +x scripts/*.sh solucao/*.sh
   ```

3. Construa e suba o ambiente:

   ```bash
   ./scripts/reset.sh
   ```

4. Confirme que o site responde. Guarde esta resposta como referência do estado normal:

   ```bash
   curl -I http://localhost:8080
   ```

   O esperado é `HTTP/1.1 200 OK`.

5. Confirme pelo diagnóstico:

   ```bash
   ./scripts/diagnostico.sh
   ```

   O esperado é `RESULTADO: ambiente saudável.`

## Como usar

| Objetivo | Comando |
| --- | --- |
| Quebrar o ambiente com as 5 falhas | `./scripts/inject_problems.sh` |
| Quebrar só algumas falhas (por exemplo, 1 e 3) | `./scripts/inject_problems.sh 1 3` |
| Entrar no container para investigar | `docker exec -it lab-nginx bash` |
| Ver o estado de cada camada | `./scripts/diagnostico.sh` |
| Ver regras, causas e correções | `./scripts/diagnostico.sh --explicar` |
| Estudar a resolução de um problema | `./solucao/p3_firewall.sh` (pausa entre as etapas) |
| Resolver tudo sem pausas | `./solucao/resolver_tudo.sh --direto` |
| Voltar ao estado inicial | `./scripts/reset.sh` |

Roteiro de estudo sugerido:

1. `./scripts/reset.sh` e `./scripts/inject_problems.sh`.
2. Investigue sozinho, de fora (host) para dentro (container).
3. Travou? Rode `./scripts/diagnostico.sh` para saber quais camadas falham, sem a resposta.
4. Ainda travado? `./scripts/diagnostico.sh --explicar` ou o script do problema em `solucao/`.
5. Refaça com `./scripts/inject_problems.sh <n>` para treinar cada falha isoladamente.

## Diagnóstico automático

O `scripts/diagnostico.sh` funciona em três passos:

1. **Coleta fatos**, cada um verdadeiro ou falso: o container está ativo? o firewall bloqueia a porta 80? o Nginx está rodando? a porta 80 está aberta? a configuração é válida? o usuário `www-data` consegue ler o site? e os logs?
2. **Aplica regras booleanas** para concluir qual problema está ativo. Exemplo: `P2 = container_ativo E NÃO config_valida`. Há também regras combinadas, como "Nginx parado E configuração inválida", que avisa que o processo não vai subir antes de corrigir a configuração.
3. **Confere o sintoma**: prevê o que o `curl` deveria mostrar (timeout, recusa, 403 ou 200) e compara com o que foi observado. Se não bater, existe algo fora das regras.

O código de saída é uma máscara de bits, útil para automação:

| Problema | Valor |
| --- | --- |
| P1 | 1 |
| P2 | 2 |
| P3 | 4 |
| P4 | 8 |
| P5 | 16 |
| Container parado | 64 |

Exemplo: saída 17 = P1 + P5. Saída 0 = ambiente saudável.

## Problemas comuns do próprio ambiente

| Sintoma | Causa provável | Solução |
| --- | --- | --- |
| `permission denied while trying to connect to the Docker daemon` | Usuário fora do grupo `docker` | `sudo usermod -aG docker $USER` e abrir uma nova sessão |
| `Bind for 0.0.0.0:8080 failed: port is already allocated` | Porta 8080 em uso | Liberar a porta ou trocar `8080:80` no `docker-compose.yml` (e a URL nos scripts) |
| `docker: 'compose' is not a docker command` | Compose v1 ou ausente | Instalar o plugin `docker-compose-plugin` |
| `iptables: Permission denied` ao injetar | Container sem `NET_ADMIN` | Conferir `cap_add` no `docker-compose.yml` e rodar `./scripts/reset.sh` |
| Build falha no `apt-get` | Sem internet ou proxy | Verificar a rede do host e rodar de novo |

## Remoção

```bash
docker compose down
docker rmi lab-nginx-web
```

## Licença

MIT. Veja [LICENSE](LICENSE).
