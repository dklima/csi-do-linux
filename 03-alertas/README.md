# Alertas de Segurança no Graylog

Configurações de alertas, pipelines e notificações para detecção proativa de incidentes.

Parte da série **CSI do Linux** sobre auditoria em ambientes Linux.

## Pré-requisitos

- Graylog 7.x funcionando ([Parte 01](../01-graylog/))
- tlog configurado para enviar logs ([Parte 02](../02-tlog/))

## Arquivos

| Arquivo | Descrição |
|---------|-----------|
| `alertas-seguranca.json` | Content Pack com 6 alertas prontos |
| `compose-email.yaml` | Extensão do compose com configuração SMTP |
| `.env.example` | Variáveis de ambiente incluindo email |
| `pipeline-after-hours.txt` | Regra de pipeline para marcar atividade fora de horário |
| `slack-payload-completo.json` | Payload formatado para notificações Slack |
| `test-alerts.sh` | Script para testar disparo dos alertas |

## Alertas incluídos

| # | Alerta | Prioridade |
|---|--------|------------|
| 1 | SSH Root Login Detected | High |
| 2 | Brute Force Attempt Detected | High |
| 3 | Dangerous Command Executed | Medium |
| 4 | Privileged User Session Started | Low |
| 5 | After-Hours Activity Detected | Medium |
| 6 | First Time User-Server Access | Medium |

## Configuração de Email

1. Copie as variáveis de ambiente:

```bash
cp .env.example .env
```

2. Edite o `.env` com suas credenciais SMTP:

```bash
GRAYLOG_TRANSPORT_EMAIL_HOSTNAME=smtp.seudominio.com.br
GRAYLOG_TRANSPORT_EMAIL_PORT=587
GRAYLOG_TRANSPORT_EMAIL_AUTH_USERNAME=alertas@seudominio.com.br
GRAYLOG_TRANSPORT_EMAIL_AUTH_PASSWORD=senha_do_email
```

3. Aplique as mudanças:

```bash
sudo podman-compose -f compose-email.yaml up -d
```

> **Atenção:** Use `up -d`, não `restart`. O restart não recarrega variáveis de ambiente.

## Importando o Content Pack

1. Acesse **System > Content Packs > Upload**
2. Selecione `alertas-seguranca.json`
3. Revise os componentes e clique em **Install**

Após importar, configure as notificações (email/Slack) em cada Event Definition.

## Pipeline de Horário Comercial

Para o alerta de atividade fora de horário funcionar:

1. Crie a regra em **System > Pipelines > Manage Rules**
2. Cole o conteúdo de `pipeline-after-hours.txt`
3. Crie um Pipeline e adicione a regra
4. Conecte o Pipeline ao Stream desejado em **Streams > Manage Pipelines**

> **Fuso horário:** A regra assume UTC. Ajuste os valores de `hour()` conforme seu timezone.

## Testando os Alertas

```bash
chmod +x test-alerts.sh
./test-alerts.sh all
```

O script envia mensagens que disparam cada alerta. Verifique em **Alerts > Events**.

### Testes individuais

```bash
./test-alerts.sh root      # Alerta 1: Login root
./test-alerts.sh brute     # Alerta 2: Brute force
./test-alerts.sh dangerous # Alerta 3: Comandos perigosos
./test-alerts.sh privileged # Alerta 4: Sessão privilegiada
```

## Troubleshooting

**Alerta não dispara:**
1. Teste a query manualmente em **Search**
2. Verifique se o Stream está recebendo mensagens
3. Confirme que a Event Definition está habilitada

**Notificação não chega:**
1. Use **Test Notification** na configuração da notification
2. Verifique logs: `sudo podman logs graylog | grep -i smtp`

**Muitos falsos positivos:**
- Ajuste thresholds de agregação
- Adicione exceções com `NOT source:IP` na query
- Popule lookup tables com acessos conhecidos

## Artigo completo

[Transformando logs em alertas](https://fogonacaixadagua.com.br/2025/12/alertas-graylog-seguranca/)
