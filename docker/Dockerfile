FROM nginxinc/nginx-unprivileged:stable-alpine

COPY app/ /usr/share/nginx/html/
COPY docker/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
