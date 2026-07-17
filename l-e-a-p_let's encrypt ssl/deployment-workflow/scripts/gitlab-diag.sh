#!/usr/bin/env bash
# =============================================================================
#  gitlab-diag.sh — Diagnostik cepat GitLab CE
#
#  Usage:
#    sudo bash gitlab-diag.sh [--follow] [--section <nama>]
#
#  Sections:
#    all         Jalankan semua (default)
#    status      Status container
#    nginx       Log NGINX (access + error)
#    rails       Log Rails (application errors)
#    puma        Log Puma (Ruby app server)
#    workhorse   Log GitLab Workhorse
#    reconfigure Log reconfigure terakhir
#    sidekiq     Log Sidekiq (background jobs)
#    socket      Cek UNIX socket tersedia
#    port        Cek port binding di host
#    letsencrypt Log Let's Encrypt
# =============================================================================
set -euo pipefail

GITLAB_DIR="/opt/gitlab"
COMPOSE="docker compose -f ${GITLAB_DIR}/docker-compose.yml"
FOLLOW=false

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
hdr()  { echo -e "\n${CYAN}${BOLD}══ $* ══${NC}"; }
ok()   { echo -e "  ${GREEN}✔${NC}  $*"; }
warn() { echo -e "  ${YELLOW}✘${NC}  $*"; }
err()  { echo -e "  ${RED}✘${NC}  $*"; }

SECTIONS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --follow|-f)  FOLLOW=true; shift ;;
    --section|-s) shift
                  # Ambil semua token berikutnya yang bukan flag (tidak diawali --)
                  while [[ $# -gt 0 && "$1" != --* ]]; do
                    SECTIONS+=("$1"); shift
                  done ;;
    *) echo "Argumen tidak dikenal: $1"; shift ;;
  esac
done
# Default ke all jika tidak ada section dipilih
[[ ${#SECTIONS[@]} -eq 0 ]] && SECTIONS=("all")

[[ $EUID -eq 0 ]] || { echo "Jalankan sebagai root: sudo bash $0"; exit 1; }

_compose_running() {
  $COMPOSE ps --quiet 2>/dev/null | grep -q .
}

_exec() {
  # Eksekusi perintah di dalam container gitlab
  $COMPOSE exec -T gitlab bash -c "$1" 2>/dev/null
}

_log_file() {
  # Tail log file di dalam volume (mount langsung dari host)
  local file="${GITLAB_DIR}/logs/${1}"
  if [[ -f "$file" ]]; then
    if $FOLLOW; then
      tail -f "$file"
    else
      tail -n 50 "$file"
    fi
  else
    warn "File tidak ditemukan: ${file}"
  fi
}

# =============================================================================
section_status() {
  hdr "STATUS CONTAINER"
  if ! _compose_running; then
    err "Container gitlab TIDAK berjalan."
    echo ""
    echo "  Coba jalankan:"
    echo "    ${COMPOSE} up -d"
    echo "    ${COMPOSE} logs --tail=50 gitlab"
    return
  fi

  $COMPOSE ps
  echo ""

  # Cek apakah reconfigure sudah selesai
  local rc_done
  rc_done="$(_exec 'gitlab-ctl status 2>/dev/null | grep -c "run:"' || echo 0)"
  if [[ "$rc_done" -gt 3 ]]; then
    ok "gitlab-ctl: ${rc_done} service berjalan"
  else
    warn "gitlab-ctl: hanya ${rc_done} service berjalan — mungkin masih reconfigure"
  fi

  # Cek socket
  local sock_wh="/var/opt/gitlab/gitlab-workhorse/sockets/socket"
  local sock_puma="/var/opt/gitlab/gitlab-rails/sockets/gitlab.socket"
  _exec "test -S ${sock_wh}  && echo ok || echo missing" | grep -q ok \
    && ok "Socket workhorse: ada" || warn "Socket workhorse: TIDAK ADA"
  _exec "test -S ${sock_puma} && echo ok || echo missing" | grep -q ok \
    && ok "Socket puma: ada"      || warn "Socket puma: TIDAK ADA"
}

# =============================================================================
section_port() {
  hdr "PORT BINDING DI HOST"
  echo "  (ss -tlnp — port yang di-listen Docker di host)"
  echo ""
  ss -tlnp 2>/dev/null | grep -E ':(80|443|2222)\s' || warn "Port 80/443/2222 tidak terdeteksi di host"
}

# =============================================================================
section_nginx() {
  hdr "NGINX — ERROR LOG (50 baris terakhir)"
  # GitLab CE: nginx error log ada di nginx/current atau nginx/gitlab_error.log
  local found=false
  for f in     "${GITLAB_DIR}/logs/nginx/current"     "${GITLAB_DIR}/logs/nginx/gitlab_error.log"     "${GITLAB_DIR}/logs/nginx/error.log"; do
    if [[ -f "$f" ]]; then
      $FOLLOW && tail -f "$f" || tail -n 50 "$f"
      found=true; break
    fi
  done
  $found || warn "Nginx error log belum ada — mungkin masih reconfigure"

  if ! $FOLLOW; then
    hdr "NGINX — ACCESS LOG (20 baris terakhir)"
    for f in       "${GITLAB_DIR}/logs/nginx/gitlab_access.log"       "${GITLAB_DIR}/logs/nginx/access.log"; do
      if [[ -f "$f" ]]; then
        tail -n 20 "$f"; found=true; break
      fi
    done
    $found || warn "Nginx access log belum ada"
  fi
}

# =============================================================================
section_rails() {
  hdr "RAILS — production.log (50 baris terakhir)"
  _log_file "gitlab-rails/production.log"
}

# =============================================================================
section_puma() {
  hdr "PUMA — stderr.log"
  _log_file "puma/puma_stderr.log"
  hdr "PUMA — stdout.log"
  if ! $FOLLOW; then
    local f="${GITLAB_DIR}/logs/puma/puma_stdout.log"
    [[ -f "$f" ]] && tail -n 30 "$f" || warn "puma_stdout.log tidak ditemukan"
  fi
}

# =============================================================================
section_workhorse() {
  hdr "WORKHORSE — current log"
  _log_file "gitlab-workhorse/current"
}

# =============================================================================
section_reconfigure() {
  hdr "RECONFIGURE — log terakhir"
  # Log reconfigure ada di dalam container
  if _compose_running; then
    _exec 'tail -n 80 /var/log/gitlab/reconfigure/*.log 2>/dev/null || \
           ls /var/log/gitlab/reconfigure/ 2>/dev/null || \
           echo "(tidak ada log reconfigure)"'
  else
    warn "Container tidak berjalan, tidak bisa baca log reconfigure."
  fi
}

# =============================================================================
section_sidekiq() {
  hdr "SIDEKIQ — current log (50 baris terakhir)"
  _log_file "sidekiq/current"
}

# =============================================================================
section_letsencrypt() {
  hdr "LET'S ENCRYPT — log"
  _log_file "letsencrypt/letsencrypt.log"
}

# =============================================================================
section_socket() {
  hdr "UNIX SOCKET CHECK"
  if ! _compose_running; then
    err "Container tidak berjalan."; return
  fi
  _exec '
    for s in \
      /var/opt/gitlab/gitlab-workhorse/sockets/socket \
      /var/opt/gitlab/gitlab-rails/sockets/gitlab.socket; do
      if [ -S "$s" ]; then
        echo "  OK   : $s"
      else
        echo "  MISS : $s"
      fi
    done
  '
}

# =============================================================================
# MAIN
# =============================================================================
echo ""
echo -e "${CYAN}${BOLD}GitLab Diagnostik — ${GITLAB_DIR}${NC}"
echo -e "Waktu: $(date)"
echo ""

_run_section() {
  case "$1" in
    status)      section_status ;;
    port)        section_port ;;
    nginx)       section_nginx ;;
    rails)       section_rails ;;
    puma)        section_puma ;;
    workhorse)   section_workhorse ;;
    reconfigure) section_reconfigure ;;
    sidekiq)     section_sidekiq ;;
    letsencrypt) section_letsencrypt ;;
    socket)      section_socket ;;
    all)
      section_status
      section_port
      section_socket
      section_nginx
      section_puma
      section_workhorse
      section_rails
      section_reconfigure
      ;;
    *) echo "Section tidak dikenal: $1"; exit 1 ;;
  esac
}

for _sec in "${SECTIONS[@]}"; do
  _run_section "$_sec"
done

echo ""