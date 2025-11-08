# behind-CDN-extended-checker
Behind CDN + ray IDs with on / off colorized DNS over http and https by URLs online | offline status codes and IPv4, IPv6 resolving advanced checker.

Simply add your URL and it will check it all for you in one go, one liner on your command line. I wrote it for web-hosting abuse departments that sometimes struggle to locate abusers initially in order to see how to act onwards. It's nothing much in terms of output, but it may take some elbow grease to compile it together to identify it all manually.

The output looks like this:

http | Online via DNS: ✅ | IPv4: 192.142.10.159 (200) | IPv6: N/A (200) | CDN: No CDN (Server: LiteSpeed) (may redirect to HTTPS)       
https | Online via DNS: ✅ | IPv4: 192.142.10.159 (200) | IPv6: N/A (200) | CDN: No CDN

or like this:

http | Online via DNS: ✅ | IPv4: 104.21.39.111 (301) | IPv6: 2606:4700:3030::ac43:9094 (301) | CDN: Cloudflare (cf-ray: 999d444f1d325008-IAD) (may redirect to HTTPS)    
https | Online via DNS: ✅ | IPv4: 104.21.39.111 (200) | IPv6: 2606:4700:3030::ac43:9094 (200) | CDN: Cloudflare (cf-ray: 999d44621ca728c6-IAD)

or like this:

http | Online via DNS: ❌ | IPv4: N/A (000) | IPv6: N/A (000) | CDN: No CDN  (may redirect to HTTPS)    
https | Online via DNS: ❌ | IPv4: N/A (000) | IPv6: N/A (000) | CDN: No CDN
