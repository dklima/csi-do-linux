#!/bin/bash
# extract-session.sh - Extrai e reproduz uma sessão tlog
#
# Uso: ./extract-session.sh <TLOG_REC_ID>
# Exemplo: ./extract-session.sh 7eeedfc2-1a46-ae0f7

if [ -z "$1" ]; then
    echo "Uso: $0 <TLOG_REC_ID>"
    echo "Exemplo: $0 7eeedfc2..."
    exit 1
fi

SESSION_ID="$1"
TEMP_FILE=$(mktemp)

# Tenta extrair do journal primeiro (funciona com writer syslog e journal)
if journalctl -t tlog -o cat --no-pager 2>/dev/null | grep "$SESSION_ID" > "$TEMP_FILE" && [ -s "$TEMP_FILE" ]; then
    echo "Sessão encontrada no journal. Reproduzindo..."
    tlog-play -r file --file-path "$TEMP_FILE"
else
    # Tenta dos arquivos de log (authpriv vai pro /var/log/secure no RHEL)
    for log in /var/log/secure /var/log/messages /var/log/auth.log /var/log/syslog; do
        if [ -f "$log" ]; then
            grep "tlog.*$SESSION_ID" "$log" | sed 's/^.*\({.*}\).*$/\1/' > "$TEMP_FILE"
            if [ -s "$TEMP_FILE" ]; then
                echo "Sessão encontrada em $log. Reproduzindo..."
                tlog-play -r file --file-path "$TEMP_FILE"
                rm -f "$TEMP_FILE"
                exit 0
            fi
        fi
    done

    echo "Sessão $SESSION_ID não encontrada."
    rm -f "$TEMP_FILE"
    exit 1
fi

rm -f "$TEMP_FILE"
