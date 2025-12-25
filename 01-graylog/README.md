# Servidor de Logs com Graylog

Stack completa para logs centralizados usando Graylog, OpenSearch e MongoDB via containers.

Parte da série **CSI do Linux** sobre auditoria em ambientes Linux.

## Stack

| Componente | Versão | Função |
|------------|--------|--------|
| Graylog | 7.0 | Interface web e processamento de logs |
| OpenSearch | 2.19.0 | Armazenamento e busca |
| MongoDB | 7.0 | Configurações do Graylog |

## Pré-requisitos

- Linux com Podman e podman-compose (ou Docker)
- Mínimo 4GB RAM, 64GB disco
- Ajuste de kernel para o OpenSearch:

```bash
sudo sysctl -w vm.max_map_count=262144
sudo cp 01-max-map-count.conf /etc/sysctl.d/
```

## Configuração

```bash
cp .env.example .env
```

Edite o `.env` com suas credenciais:

- **GRAYLOG_PASSWORD_SECRET**: `openssl rand -base64 32`
- **GRAYLOG_ROOT_PASSWORD_SHA2**: `printf '%s' "SuaSenha" | sha256sum | cut -d' ' -f1`
- **GRAYLOG_HTTP_EXTERNAL_URI**: IP do servidor (ex: `http://192.168.1.100:9000/`)
- **OPENSEARCH_INITIAL_ADMIN_PASSWORD**: Senha forte (8+ chars, maiúscula, minúscula, número, especial)

## Executando

```bash
sudo podman-compose up -d
```

### Conflito com DNS local (porta 53)

Se o servidor já tiver DNS rodando (dnsmasq, bind, systemd-resolved), use o compose alternativo com IPs fixos:

```bash
sudo podman network create --disable-dns --subnet 172.20.0.0/24 graylog-net
sudo podman-compose -f compose-no-dns.yaml up -d
```

IPs atribuídos: MongoDB `172.20.0.10`, OpenSearch `172.20.0.11`, Graylog `172.20.0.12`

A primeira inicialização leva 2-3 minutos. Para acompanhar:

```bash
sudo podman-compose logs -f graylog
```

## Acesso

- **URL**: `http://SEU_IP:9000`
- **Usuário**: admin
- **Senha**: a que você usou para gerar o SHA256

## Portas

| Porta | Protocolo | Uso |
|-------|-----------|-----|
| 9000 | TCP | Interface web |
| 1514 | UDP/TCP | Recebimento de logs (Syslog) |

## Firewall

No Fedora/RHEL com firewalld:

```bash
sudo firewall-cmd --add-port=9000/tcp --permanent
sudo firewall-cmd --add-port=1514/udp --permanent
sudo firewall-cmd --add-port=1514/tcp --permanent
sudo firewall-cmd --reload
```

Para restringir por rede de origem (recomendado):

```bash
# Liberar apenas para a rede interna
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" port port="1514" protocol="udp" accept'
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" port port="1514" protocol="tcp" accept'
sudo firewall-cmd --reload
```

## Testando

**Importante**: Antes de testar, crie um Input na interface do Graylog:
1. Acesse `http://SEU_IP:9000`
2. Vá em **System** → **Inputs**
3. Selecione **Syslog UDP** → **Launch new input**
4. Configure: Node=Global, Title=Syslog UDP, Port=1514
5. Clique em **Launch input**

Depois, envie um log de teste:

```bash
logger -n SEU_IP -P 1514 --udp "Teste de log remoto"
```

A mensagem aparece em **Search** na interface do Graylog.

### Troubleshooting

Se as mensagens não aparecerem:

1. Verifique se o Input está com status "RUNNING" (não "SETUP")
2. Se estiver em "SETUP", clique no Input → "More actions" → "Start input"
3. Se persistir, reinicie o container: `sudo podman restart graylog`

## Iniciar no boot

Para o stack subir automaticamente após reboot:

```bash
# Mover arquivos para local definitivo
sudo mkdir -p /opt/graylog
sudo cp compose.yaml .env /opt/graylog/

# Instalar e habilitar o serviço
sudo cp graylog.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable graylog.service
```

Controle manual:

```bash
sudo systemctl start graylog    # Inicia
sudo systemctl stop graylog     # Para
sudo systemctl status graylog   # Verifica status
```

## Compatibilidade

> **Atenção**: O Graylog não suporta OpenSearch 3.x. Use apenas a série 2.x.

## Artigo completo

[Montando seu servidor de logs com Graylog](https://fogonacaixadagua.com.br/2025/12/graylog-logs-centralizados-tutorial)
