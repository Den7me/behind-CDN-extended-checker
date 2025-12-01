# Behind-CDN Origin Checker

![Bash](https://img.shields.io/badge/Bash-Yes-green)
![License](https://img.shields.io/github/license/Den7me/behind-CDN-extended-checker)
![Last Commit](https://img.shields.io/github/last-commit/Den7me/behind-CDN-extended-checker/main)
[![Open in Gitpod](https://img.shields.io/badge/Open%20in-Gitpod-blue?logo=gitpod)](https://gitpod.io/#https://github.com/Den7me/behind-CDN-extended-checker)
[![Open in Codespaces](https://img.shields.io/badge/Open%20in-Codespaces-blue?logo=github)](https://github.com/codespaces/new?repo=Den7me/behind-CDN-extended-checker)

A Bash script to check if a website is behind a CDN (Content Delivery Network) and retrieve origin server information. This script detects if a website is using popular CDNs such as Cloudflare, Akamai, Fastly, CloudFront, StackPath, KeyCDN, Incapsula, Google Cloud CDN, Azure CDN, BunnyCDN, CDN77, and CacheFly. It fetches IPv4 and IPv6 addresses, checks HTTP/HTTPS response codes directly and via origin, retrieves SSL certificate details (CN, SAN, issuer), shows hostname and organization info for the origin IP, and detects EPP domain status.

## Table of Contents

- [Features](#features)  
- [Requirements](#requirements)  
- [Installation](#installation)  
- [Usage](#usage)  
- [Example Output](#example-output)  
- [Origin / Direct IP Checks](#origin--direct-ip-checks)  
- [Notes](#notes)  
- [License](#license)  

## Features

- Detects usage of popular CDNs  
- Retrieves IPv4 and IPv6 addresses  
- Checks HTTP and HTTPS response codes directly and via origin  
- Retrieves SSL certificate details: CN, SAN, issuer  
- Shows hostname and organization info for origin IP  
- Detects EPP domain status  
- Fully commented, easy to understand and safe to run  

## Requirements

- Bash (tested on Debian/Ubuntu)  
- curl  
- dig  
- openssl  
- jq (for JSON parsing)  

## Installation

Clone the repository:

    git clone https://github.com/Den7me/behind-CDN-extended-checker.git
    cd behind-CDN-extended-checker

Make the script executable:

    chmod +x cdn-origin-check.sh

## Usage

:warning: **Important Development Notice (Work in Progress)**

CLI arguments and multi-domain support are currently being developed (finishing touches).
> Until the next release, please edit the `url="https://example.com"` variable directly inside the script.
> Enter the url you would like to check manually, for example `url="https://mydomain.com"`

### Option 1: Pass domain as a command-line argument

    ./cdn-origin-check.sh https://example.com

### Option 2: Edit the script manually

Edit the first line of `cdn-origin-check.sh`:

    url="https://example.com"

Then run:

    ./cdn-origin-check.sh

### Option 3: Check multiple domains in a loop

    urls=("https://example1.com" "https://example2.com")
    for url in "${urls[@]}"; do
        ./cdn-origin-check.sh "$url"
    done

## Example Output:

| PROTO | DNS | WEB | IPv4 (CODE)           | IPv6 (CODE) | CDN               |
|-------|-----|-----|----------------------|-------------|-----------------|
| HTTP  | :heavy_check_mark:  | :heavy_check_mark:  | 198.51.100.10 (200)  | N/A         | No CDN (Apache)  |
| HTTPS | :heavy_check_mark:  | :x:  | 198.51.100.10 (403)  | N/A         | No CDN ()        |


## Origin / Direct IP Checks

    IP: 198.51.100.10
      HTTP IP: 200  HTTP hostname: 198.51.100.10  HTTPS IP: 403  HTTPS hostname: 198.51.100.10
      Cert present: yes
      SSL CN: example.com
      SSL SAN: example.com, www.example.com
      Issuer CN: Example CA
      Hostname: example.com
      Org: Example Organization

    NS: ns1.example.com. ns2.example.com.
    REGISTRAR: Example Registrar
    EPP STATUS CODE: clientTransferProhibited

## Notes

- The script is read-only and safe to run.  
- Designed for diagnostic and auditing purposes.  
- Can be adapted to check multiple domains in a loop.  
- Works on Debian/Ubuntu and other Bash-supported systems.  
- Ensure `jq` is installed to parse JSON from RDAP responses.  
- If behind a CDN, direct origin IP checks may not return real origin IPs (expected).  
- Output formatting may vary slightly depending on terminal font and width.  

## License

MIT License © 2025 Dennis aka Den7 (Klaipedaville)