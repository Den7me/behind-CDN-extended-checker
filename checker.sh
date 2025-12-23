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
if [ "$#" -gt 0 ]; then
    urls=("$@")
else
    urls=("https://ultahost.com")
fi

# -------------------------
# FUNCTIONS
# -------------------------

# CDN detection
detect_cdn() {
    s="$1" v="$2" x="$3" h="$4"
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

# Spinner (cosmetic only, no data access)
spinner() {
    local pid=$1
    local spin='|/-\'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r%s %c" "running RDAP/Whois.. please, hold.." "${spin:$i:1}" >&2
        sleep 0.2
    done
    printf "\r\033[2K\n" >&2
}

# Format date to human-readable form
format_date() {
    local d="$1"
    if [[ -n "$d" ]]; then
        # Normalize missing time / Z
        if [[ "$d" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}$ ]]; then
            d="${d}:00:00Z"
        elif [[ "$d" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            d="${d}T00:00:00Z"
        fi
        # Convert to human-readable
        formatted=$(date -d "$d" +"%b-%d-%Y" 2>/dev/null)
        echo "${formatted:-$d}"
    else
        echo "not exposed / restricted"
    fi
}

# Single domain scan (sequential, stable)
scan_domain() {
    local url="$1"
    echo -e "\n========================"
    echo "Processing: $url"
    echo "========================"
    d=${url#*://}
    d=${d%%/*}

    # -------------------------
    # DNS LOOKUPS
    # -------------------------
    ipv4=$(dig +short A "$d" | head -n1)
    ipv6=$(dig +short AAAA "$d" | head -n1)
    is_cdn="no"

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
        v=$(grep -i '^Via:' <<<"$h" | tail -n1 | sed -E 's/^[Vv]ia:[[:space:]]*//')
        x=$(grep -i '^X-Cache:' <<<"$h" | tail -n1 | sed -E 's/^[Xx]-Cache:[[:space:]]*//')
        cf=$(grep -i '^CF-RAY:' <<<"$h" | tail -n1 | awk '{print $2}')
        lbl=$(detect_cdn "$s" "$v" "$x" "$h")
        [[ "$lbl" != "No CDN" ]] && is_cdn="yes"
        if [ -n "$ipv4" ]; then ip4s[$proto]="$ipv4 ($c)"; else ip4s[$proto]="— (N/A)"; fi
        if [ -n "$ipv6" ]; then ip6s[$proto]="$ipv6 ($c)"; else ip6s[$proto]="— (N/A)"; fi
        if [[ "$lbl" == "Cloudflare" ]]; then cdns[$proto]="Cloudflare ($s, CF-RAY: ${cf:-none})"; else cdns[$proto]="$lbl ($s)"; fi
        codes[$proto]="$c"
        web[$proto]="$([ "$c" != "N/A" ] && echo '✅' || echo '❌')"
    done

    # -------------------------
    # TABLE FORMATTING
    # -------------------------
    max4=${#ip4s[http]}; (( ${#ip4s[https]} > max4 )) && max4=${#ip4s[https]}
    max6=${#ip6s[http]}; (( ${#ip6s[https]} > max6 )) && max6=${#ip6s[https]}
    maxc=${#cdns[http]}; (( ${#cdns[https]} > maxc )) && maxc=${#cdns[https]}
    printf "%s\n" "$(printf '%-6s' 'PROTO') |$(printf '%-3s' 'DNS') |$(printf '%-3s' 'WEB') | $(printf '%-*s' "$max4" 'IPv4') | $(printf '%-*s' "$max6" 'IPv6') | $(printf '%-*s' "$maxc" 'CDN')"
    dns_status="❌"
    [ -n "$ipv4" ] || [ -n "$ipv6" ] && dns_status="✅"
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
        hb=$(curl -skI --max-redirs 1 "http://$h" -o /dev/null -w "%{http_code}" 2>/dev/null || echo N/A)
        hh=$(curl -skI -H "Host: $d" --max-redirs 1 "http://$h" -o /dev/null -w "%{http_code}" 2>/dev/null || echo N/A)
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
    # REGISTRAR / CREATION / EXPIRY (RDAP + WHOIS)
    # -------------------------
    rdap_tmp=$(mktemp)

    {
        tld=${d##*.}
        rdap_urls=( "https://rdap.org/domain/$d" "https://rdap.nic.$tld/domain/$d" )
        registrar=""; creation_date_msg=""; expiry_date_msg=""
        for rdap_url in "${rdap_urls[@]}"; do
            rdap_json=$(timeout 15 curl -s -H "Accept: application/json" "$rdap_url")
            registrar=$(echo "$rdap_json" | grep -Po '"registrarName"\s*:\s*"\K[^"]+' | head -n1)
            creation_date_msg=$(echo "$rdap_json" | grep -Po '"eventAction"\s*:\s*"registration".*?"eventDate"\s*:\s*"\K[^"]+' | head -n1)
            expiry_date_msg=$(echo "$rdap_json" | grep -Po '"eventAction"\s*:\s*"expiration".*?"eventDate"\s*:\s*"\K[^"]+' | head -n1)
            [[ -n "$registrar" ]] && break
        done
        [[ -z "$registrar" ]] && registrar=$(timeout 15 whois "$d" 2>/dev/null | awk -F: '/Registrar:/{print $2; exit}' | xargs)
        [[ -z "$creation_date_msg" ]] && creation_date_msg=$(timeout 15 whois "$d" 2>/dev/null | awk -F: '/Creation Date:|Created On:|Registered On:/ {print $2; exit}' | xargs)
        [[ -z "$expiry_date_msg" ]] && expiry_date_msg=$(timeout 15 whois "$d" 2>/dev/null | awk -F: '/Expiry Date:|Expiration Date:|Registrar Registration Expiration Date:/ {print $2; exit}' | xargs)
        [[ -z "$registrar" ]] && registrar="REDACTED (registry privacy enforced)"
        creation_date_human=$(format_date "$creation_date_msg")
        expiry_date_human=$(format_date "$expiry_date_msg")
        printf "REGISTRAR: %s\nCREATION DATE: %s\nEXPIRY DATE: %s\n" \
            "$registrar" "$creation_date_human" "$expiry_date_human" >"$rdap_tmp"
    } &
    rdap_pid=$!
    spinner "$rdap_pid"
    wait "$rdap_pid"
    cat "$rdap_tmp"
    rm -f "$rdap_tmp"

    # -------------------------
    # EPP STATUS
    # -------------------------
    raw_status=$(timeout 15 whois "$d" 2>/dev/null | awk -F: '/Domain Status:/{print $2; exit}' | tr '[:upper:]' '[:lower:]' | xargs)
    epp_status=$(echo "$raw_status" | awk '{print $1}')
    case "$epp_status" in
        clienthold*) epp_status="clientHold" ;;
        serverhold*) epp_status="serverHold" ;;
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
}

# -------------------------
# MAIN LOOP (SEQUENTIAL)
# -------------------------
for url in "${urls[@]}"; do
    scan_domain "$url"
done

