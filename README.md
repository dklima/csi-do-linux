# CSI do Linux

Série de artigos sobre auditoria, monitoramento e resposta a incidentes em ambientes Linux.

Cada diretório contém os arquivos necessários para reproduzir o tutorial correspondente.

## Artigos

| # | Tema | Diretório | Status |
|---|------|-----------|--------|
| 01 | [Servidor de Logs com Graylog](https://fogonacaixadagua.com.br/2025/12/graylog-logs-centralizados-tutorial) | [01-graylog](./01-graylog) | ✅ Publicado |
| 02 | Auditoria de Terminal | em breve | 🚧 Em desenvolvimento |

## Pré-requisitos gerais

- Linux (Fedora 43+ ou Ubuntu 24.04+ recomendados)
- Podman e podman-compose (ou Docker)
- Conhecimento básico de terminal e containers

## Estrutura

```
public_repo/
├── 01-graylog/          # Logs centralizados com Graylog + OpenSearch
│   ├── compose.yaml
│   ├── .env.example
│   └── ...
├── 02-terminal-audit/   # (em breve)
└── ...
```

## Autor

**DK**
[fogonacaixadagua.com.br](https://fogonacaixadagua.com.br)

## Licença

MIT
