# Gravação de Sessões com tlog

Configuração do tlog para gravar sessões de terminal e enviar para o Graylog via rsyslog.

Parte da série **CSI do Linux** sobre auditoria em ambientes Linux.

## Pré-requisitos

- Graylog funcionando ([Parte 01](../01-graylog/))
- Linux com rsyslog (Fedora 44+, RHEL 9+, ou Ubuntu 24.04+)
- Acesso root

## Arquivos

| Arquivo | Descrição |
|---------|-----------|
| `tlog-rec-session.conf` | Configuração do tlog para usar syslog |
| `10-graylog.conf` | Regra rsyslog para encaminhar logs ao Graylog |
| `sssd.conf.example` | Exemplo de configuração SSSD para gravação centralizada |
| `extract-session.sh` | Script para extrair e reproduzir sessões |

## Instalação do tlog

```bash
# Fedora/RHEL
sudo dnf install tlog

# Debian/Ubuntu
sudo apt install tlog
```

## Configuração

### 1. Configurar tlog para syslog

```bash
sudo cp tlog-rec-session.conf /etc/tlog/tlog-rec-session.conf
```

O arquivo configura:
- **writer**: `syslog` (em vez de journal)
- **notice**: Aviso exibido ao usuário
- **log.input**: `false` (não grava senhas)

### 2. Criar Input TCP no Graylog

As mensagens do tlog podem ser grandes. Use TCP para evitar truncamento:

1. **System > Inputs** > selecionar **Syslog TCP**
2. **Title**: `Syslog TCP - tlog`
3. **Port**: `1514`
4. **Launch input**

### 3. Configurar rsyslog

Aumente o limite de mensagem em `/etc/rsyslog.conf`:

```bash
$MaxMessageSize 64k
```

Copie a regra de encaminhamento:

```bash
sudo cp 10-graylog.conf /etc/rsyslog.d/
```

Edite o arquivo e substitua `IP_DO_GRAYLOG` pelo IP do seu servidor.

Reinicie o rsyslog:

```bash
sudo systemctl restart rsyslog
```

### 4. Habilitar gravação para usuários

**Método 1 - Trocar shell (funciona sempre):**

```bash
sudo usermod -s /usr/bin/tlog-rec-session usuario
```

**Método 2 - SSSD (para AD/LDAP):**

```bash
sudo cp sssd.conf.example /etc/sssd/sssd.conf
sudo chmod 600 /etc/sssd/sssd.conf
# Edite conforme seu ambiente
sudo systemctl restart sssd
```

## Testando

```bash
# Inicia sessão gravada
tlog-rec-session

# Execute alguns comandos
ls -la
whoami
exit

# Verifique no Graylog
# Search: application_name:tlog
```

## Reproduzindo Sessões

Use o script de extração:

```bash
sudo cp extract-session.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/extract-session.sh

# Reproduzir sessão pelo ID
extract-session.sh b5bc59a1-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

O ID da sessão (`TLOG_REC`) aparece nos logs do Graylog.

## SELinux

Se o rsyslog não conseguir conectar na porta 1514:

```bash
sudo semanage port -a -t syslogd_port_t -p tcp 1514
sudo semanage port -a -t syslogd_port_t -p udp 1514
sudo systemctl restart rsyslog
```

## Troubleshooting

**Sessão não grava:**
```bash
# Verificar shell do usuário
getent passwd usuario | cut -d: -f7
# Deve retornar: /usr/bin/tlog-rec-session
```

**Logs não chegam no Graylog:**
```bash
# Testar conectividade TCP
nc -zv IP_DO_GRAYLOG 1514

# Verificar erros do rsyslog
sudo journalctl -u rsyslog -f
```

**Verificar logs locais do tlog:**
```bash
# Qualquer distro com systemd
sudo journalctl -t tlog

# Fedora/RHEL (tlog usa facility authpriv)
sudo grep tlog /var/log/secure

# Debian/Ubuntu
sudo grep tlog /var/log/auth.log
```

**Ubuntu sem rsyslog:**
```bash
sudo apt install rsyslog
sudo systemctl enable --now rsyslog
```

## Considerações de Segurança

- Avise os usuários sobre a gravação (requisito legal em alguns países)
- Proteja o acesso ao Graylog (logs contêm informação sensível)
- Defina política de retenção adequada
- Considere TLS para transporte em produção

## Artigo completo

[Gravando sessões de terminal com tlog](https://fogonacaixadagua.com.br/2025/12/tlog-gravacao-sessoes-terminal-linux/)
