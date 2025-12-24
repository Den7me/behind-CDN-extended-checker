# Behind-CDN Origin Checker

![Bash](https://img.shields.io/badge/Bash-Yes-green)
![License](https://img.shields.io/github/license/Den7me/behind-CDN-extended-checker)
![Last Commit](https://img.shields.io/github/last-commit/Den7me/behind-CDN-extended-checker/main)
[![Open in Gitpod](https://img.shields.io/badge/Open%20in-Gitpod-blue?logo=gitpod)](https://gitpod.io/#https://github.com/Den7me/behind-CDN-extended-checker)
[![Open in Codespaces](https://img.shields.io/badge/Open%20in-Codespaces-blue?logo=github)](https://github.com/codespaces/new?repo=Den7me/behind-CDN-extended-checker)
<!-- Docker Hub Badge -->
[![Docker](https://img.shields.io/docker/v/den7me/behind-cdn-extended-checker?label=Docker%20Hub)](https://hub.docker.com/r/den7me/behind-cdn-extended-checker)
<!-- GitHub Release Badge -->
[![GitHub Release](https://img.shields.io/github/v/release/Den7me/behind-CDN-extended-checker?label=GitHub%20Release)](https://github.com/Den7me/behind-CDN-extended-checker/releases)
<!-- Optional: GitHub Actions Build Badge -->
[![Docker Build & Push](https://github.com/Den7me/behind-CDN-extended-checker/actions/workflows/docker-build.yml/badge.svg)](https://github.com/Den7me/behind-CDN-extended-checker/actions/workflows/docker-build.yml)

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

    chmod +x checker.sh

## Usage

### Option 1: Pass domain as a command-line argument

    ./checker.sh https://example.com

### Option 2: Edit the script manually

Edit the line in the beginning of `checker.sh`:

    urls=("https://example.com")

Then run:

    ./checker.sh

### Option 3: Check multiple domains in a loop. It may take a tiny bit longer to run.

    ./checker.sh  https://example.com https://example2.com https://example3.com
 
## Example Output:

| PROTO | DNS | WEB | IPv4                 | IPv6                         | CDN                                       |
|-------|-----|-----|----------------------|------------------------------|-------------------------------------------|
| HTTP  | :heavy_check_mark: | :heavy_check_mark: | 198.51.100.10 (301) | 2606:4700:20::681a:a5d (301) | Cloudflare (cloudflare, CF-RAY: 9a743e468f2913bc-IAD) |
| HTTPS | :heavy_check_mark: | :heavy_check_mark: | 198.51.100.10 (200) | 2606:4700:20::681a:a5d (200) | Cloudflare (cloudflare, CF-RAY: 9a743e488885c97c-IAD) |

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
    CREATION DATE: 2022-11-23
    EXPIRY DATE: 2026-11-23
    EPP STATUS CODE: serverHold
  
## Docker Usage

    Run the checker with Docker without installing dependencies:

```bash
# Pull the image
    docker pull den7me/behind-cdn-extended-checker:2.0.1

# Run the default scan
    docker run --rm den7me/behind-cdn-extended-checker:2.0.1

# Scan a custom domain
    docker run --rm den7me/behind-cdn-extended-checker:2.0.1 https://example.com

# Optional: start an interactive container for multiple checks
    docker run -it den7me/behind-cdn-extended-checker:2.0.1 /bin/bash

# Build the image locally from source
    docker build -t den7me/behind-cdn-extended-checker:2.0.1 .


## Notes

- The script is read-only and safe to run.  
- Designed for diagnostic and auditing purposes.  
- Can be adapted to check multiple domains in a loop.  
- Works on Debian/Ubuntu and other Bash-supported systems.  
- Ensure `jq` is installed to parse JSON from RDAP responses.  
- If behind a CDN, direct origin IP checks may not return real origin IPs (expected).  
- Output formatting may vary slightly depending on terminal font and width.  
- It can be used by FBI and law enforcement provided full root whois access is authorized and granted.
- ^ The above mentioned feature is not implemented for legal and security reasons.


## License

GNU GPL v3.0 License © 2025 Dennis aka Den7 (Klaipedaville)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED.