#!/usr/bin/env bash
#
# Domain CDN / Origin / SSL / WHOIS Inspection Tool
# Author: Dennis aka Den7 (Klaipedaville)
# Description:
#   Checks DNS, HTTP/HTTPS status, CDN detection, origin IP behavior,
#   SSL certificate details, PTR/Org info, Nameservers, Registrar,
#   and EPP status in one report.
#

# -------------------------
# INPUT
# -------------------------

url="https://ultahost.com"
d=${url#*://}
d=${d%%/*}

# -------------------------
# DNS LOOKUPS
# -------------------------

ipv4=$(dig +short A "$d" | head -n1)
ipv6=$(dig +short AAAA "$d" | head -n1)

is_cdn="no"

# -------------------------
# CDN DETECTION FUNCTION
# -------------------------

detect_cdn() {
  s="$1"
  v="$2"
  x="$3"
  h="$4"

  [[ "$s" =~ [Cc]loudflare ]] || [[ "$h" =~ CF-RAY ]] && echo "Cloudflare" && return
  [[ "$s" =~ Akamai ]] || [[ "$h" =~ Akamai ]] && echo "Akamai" && return
  [[ "$v" =~ Fastly ]] || ([[ "$x" =~ HIT ]] && [[ "$h" =~ Fastly ]]) && echo "Fastly" && return
  [[ "$v" =~ CloudFront ]] || [[ "$h" =~ X-Amz-Cf-Id ]] && echo "Amazon CloudFront" && return
  [[ "$s" =~ StackPath|NetDNA ]] && echo "StackPath/MaxCDN" && return
  [[ "$s" =~ KeyCDN ]] && echo "KeyCDN" && return
  [[ "$s" =~ Incapsula ]] || [[ "$h" =~ Incapsula ]] && echo "Incapsula/Imperva" && return
  [[ "$v" =~ Google ]] && echo "Google Cloud CDN" && return
  [[ "$h" =~ X-Azure-Ref ]] || [[ "$s" =~ Azure ]] && echo "Microsoft Azure CDN" && return
  [[ "$s" =~ BunnyCDN ]] || [[ "$h" =~ X-Bunny-Cache ]] && echo "BunnyCDN" && return
  [[ "$s" =~ CDN77 ]] && echo "CDN77" && return
  [[ "$s" =~ CacheFly ]] && echo "CacheFly" && return

  echo "No CDN"
}

# -------------------------
# DATA STRUCTURES
# -------------------------

declare -A ip4s ip6s cdns codes web

# -------------------------
# HTTP / HTTPS CHECKS
# -------------------------

for proto in http https; do
  h=$(curl -sI --max-redirs 5 "$proto://$d" 2>/dev/null | tr -d '\r')

  c=$(awk '/^HTTP\//{c=$2} END{print c?c:"N/A"}' <<<"$h")
  s=$(grep -i '^Server:' <<<"$h" | tail -n1 | sed -E 's/^[Ss]erver:[[:space:]]*//')
  v=$(grep -i '^Via:' <<<"$h"    | tail -n1 | sed -E 's/^[Vv]ia:[[:space:]]*//')
  x=$(grep -i '^X-Cache:' <<<"$h" | tail -n1 | sed -E 's/^[Xx]-Cache:[[:space:]]*//')
  cf=$(grep -i '^CF-RAY:' <<<"$h" | tail -n1 | awk '{print $2}')

  lbl=$(detect_cdn "$s" "$v" "$x" "$h")
  [[ "$lbl" != "No CDN" ]] && is_cdn="yes"

  ip4s[$proto]="$([ -n "$ipv4" ] && printf "%s (%s)" "$ipv4" "$c" || printf "N/A")"
  ip6s[$proto]="$([ -n "$ipv6" ] && printf "%s (%s)" "$ipv6" "$c" || printf "N/A")"

  if [[ "$lbl" == "Cloudflare" ]]; then
    cdns[$proto]="Cloudflare ($s, CF-RAY: ${cf:-none})"
  else
    cdns[$proto]="$lbl ($s)"
  fi

  codes[$proto]="$c"
  web[$proto]="$([ "$c" != "N/A" ] && echo '?' || echo '?')"
done

# -------------------------
# TABLE FORMATTING
# -------------------------

max4=${#ip4s[http]}; (( ${#ip4s[https]} > max4 )) && max4=${#ip4s[https]}
max6=${#ip6s[http]}; (( ${#ip6s[https]} > max6 )) && max6=${#ip6s[https]}
maxc=${#cdns[http]}; (( ${#cdns[https]} > maxc )) && maxc=${#cdns[https]}

printf "%s\n" "$(printf '%-6s' 'PROTO') |$(printf '%-3s' 'DNS') |$(printf '%-3s' 'WEB') | $(printf '%-*s' "$max4" 'IPv4 (CODE)') | $(printf '%-*s' "$max6" 'IPv6 (CODE)') | $(printf '%-*s' "$maxc" 'CDN')"

dns_status="?"
[ -n "$ipv4" ] || [ -n "$ipv6" ] && dns_status="?"

for p in http https; do
  printf "%-6s | %-3s | %-3s | %-*s | %-*s | %-*s\n" \
    "$(tr '[:lower:]' '[:upper:]' <<<"$p")" \
    "$dns_status" \
    "${web[$p]}" \
    "$max4" "${ip4s[$p]}" \
    "$max6" "${ip6s[$p]}" \
    "$maxc" "${cdns[$p]}"
done

# -------------------------
# ORIGIN / SSL INSPECTION
# -------------------------

printf "\n--- ORIGIN / DIRECT IP CHECKS ---\n"

for ip in "$ipv4" "$ipv6"; do
  [ -z "$ip" ] && continue

  h=$ip

  hb=$(curl -skI --max-redirs 1 "http://$h"  -o /dev/null -w "%{http_code}" 2>/dev/null || echo N/A)
  hh=$(curl -skI -H "Host: $d" --max-redirs 1 "http://$h"  -o /dev/null -w "%{http_code}" 2>/dev/null || echo N/A)
  hs=$(curl -skI --resolve "$d:443:$h" --max-redirs 1 "https://$d" -o /dev/null -w "%{http_code}" 2>/dev/null || echo N/A)
  hbss=$(curl -skI --max-redirs 1 "https://$h" -o /dev/null -w "%{http_code}" 2>/dev/null || echo N/A)

  hb=${hb#000}; hh=${hh#000}; hs=${hs#000}; hbss=${hbss#000}

  cert=$(timeout 5 openssl s_client -servername "$d" -connect "$h:443" </dev/null 2>/dev/null | sed -ne '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p')

  cn=$(echo "$cert" | openssl x509 -noout -subject -nameopt RFC2253 2>/dev/null | sed -n 's/.*CN=\([^,\/]*\).*/\1/p')
  san=$(echo "$cert" | openssl x509 -noout -text 2>/dev/null | awk '/Subject Alternative Name/{f=1;next} f && /^ *DNS:/ {gsub(/DNS:/,""); print; if(/^$/) exit}' | tr '\n' ',' | sed 's/,$//')
  issuer=$(echo "$cert" | openssl x509 -noout -issuer -nameopt RFC2253 2>/dev/null | sed -n 's/.*CN=\(.*\)/\1/p')

  co="$([ -n "$cert" ] && echo yes || echo no)"

  j=$(curl -s "https://ipinfo.io/$h" 2>/dev/null)
  hn=$(awk -F'"' '/"hostname"/{print $4;exit}' <<<"$j")
  org=$(awk -F'"' '/"org"/{print $4;exit}' <<<"$j")

  note="$([ -z "$hn" ] && [ "$is_cdn" = "yes" ] && echo "(none expected if behind CDN/proxy)" || ([ -z "$hn" ] && echo "(probably shared hosting -> no PTR)"))"

  printf "IP: %s\n  HTTP IP: %s  HTTP hostname: %s  HTTPS IP: %s  HTTPS hostname: %s\n  Cert present: %s\n  SSL CN: %s\n  SSL SAN: %s\n  Issuer CN: %s\n  Hostname: %s %s\n  Org: %s\n\n" \
    "$h" "$hb" "$hh" "$hs" "$hbss" "$co" "${cn:-none}" "${san:-none}" "${issuer:-none}" "${hn:-none}" "$note" "${org:-none}"
done

# -------------------------
# NAMESERVERS
# -------------------------

ns=$(dig +short NS "$d" | tr '\n' ' ' | sed -e 's/[[:space:]]\+/ /g')
printf "NS: %s\n" "${ns:-NONE}"

# -------------------------
# REGISTRAR
# -------------------------

registrar=$(whois "$d" 2>/dev/null | awk -F: '/Registrar:/{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2; exit} /Sponsoring Registrar:/{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2; exit}')

if [[ -z "$registrar" ]]; then
  registrar=$(curl -s "https://www.whois.com/whois/$d" 2>/dev/null | sed -n '/Registrar:/I{ s/.*Registrar:[[:space:]]*//; s/<.*//; p; q }')
fi

[[ -z "$registrar" ]] && registrar="REDACTED"
printf "REGISTRAR: %s\n" "$registrar"

# -------------------------
# EPP STATUS
# -------------------------

raw_status=$(whois "$d" 2>/dev/null | awk -F: '/Domain Status:/{print $2; exit}' | tr '[:upper:]' '[:lower:]' | xargs)
epp_status=$(echo "$raw_status" | awk '{print $1}')

case "$epp_status" in
  clienthold*) epp_status="clientHold" ;;
  clienttransferprohibited*) epp_status="clientTransferProhibited" ;;
  clientupdateprohibited*) epp_status="clientUpdateProhibited" ;;
  pendingcreate*) epp_status="pendingCreate" ;;
  pendingdelete*) epp_status="pendingDelete" ;;
  pendingrenew*) epp_status="pendingRenew" ;;
  pendingtransfer*) epp_status="pendingTransfer" ;;
  pendingrestore*) epp_status="pendingRestore" ;;
  active*) epp_status="active" ;;
  *) epp_status="NONE" ;;
esac

printf "EPP STATUS CODE: %s\n" "$epp_status"
