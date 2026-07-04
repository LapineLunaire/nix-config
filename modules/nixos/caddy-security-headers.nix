# Caddy snippet with baseline security headers, spliced into every vhost on sparkle and sparxie.
''
  header {
    Strict-Transport-Security "max-age=31536000; includeSubDomains"
    X-Content-Type-Options "nosniff"
    Referrer-Policy "strict-origin-when-cross-origin"
    -Server
  }
''
