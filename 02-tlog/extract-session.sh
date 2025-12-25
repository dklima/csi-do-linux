#!/bin/bash
# extract-session.sh - Extrai e reproduz uma sessao tlog
#
# Uso: ./extract-session.sh <TLOG_REC_ID>
# Exemplo: ./extract-session.sh b5bc59a1-1234-5678-9abc-def012345678

if [ -z "$1" ]; then
    echo "Uso: $0 <TLOG_REC_ID>"
    echo "Exemplo: $0 b5bc59..."
    exit 1
fi

SESSION_ID="$1"
TEMP_FILE=$(mktemp)

# Tenta extrair do journal primeiro
if journalctl -o cat TLOG_REC="$SESSION_ID" > "$TEMP_FILE" 2>/dev/null && [ -s "$TEMP_FILE" ]; then
    echo "Sessao encontrada no journal. Reproduzindo..."
    tlog-play -r file --file-path "$TEMP_FILE"
else
    # Tenta do /var/log/messages ou /var/log/secure
    for log in /var/log/messages /var/log/secure /var/log/syslog; do
        if [ -f "$log" ]; then
            grep "$SESSION_ID" "$log" | sed 's/^.*\({.*}\).*$/\1/' > "$TEMP_FILE"
            if [ -s "$TEMP_FILE" ]; then
                echo "Sessao encontrada em $log. Reproduzindo..."
                tlog-play -r file --file-path "$TEMP_FILE"
                rm -f "$TEMP_FILE"
                exit 0
            fi
        fi
    done

    echo "Sessao $SESSION_ID nao encontrada."
    rm -f "$TEMP_FILE"
    exit 1
fi

rm -f "$TEMP_FILE"
