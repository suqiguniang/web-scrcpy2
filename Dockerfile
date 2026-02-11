FROM node:16-alpine

RUN apk add --no-cache nginx openssl

RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/private.key \
    -out /etc/nginx/ssl/certificate.crt \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=MyOrganization/OU=MyUnit/CN=localhost"

RUN echo 'server { \
    listen 80; \
    server_name localhost; \
    return 301 https://$server_name$request_uri; \
} \
server { \
    listen 443 ssl; \
    server_name localhost; \
    ssl_certificate /etc/nginx/ssl/certificate.crt; \
    ssl_certificate_key /etc/nginx/ssl/private.key; \
    location / { \
        proxy_pass http://127.0.0.1:5173; \
        proxy_set_header Host $host; \
        proxy_set_header X-Real-IP $remote_addr; \
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for; \
        proxy_set_header X-Forwarded-Proto $scheme; \
    } \
}' > /etc/nginx/http.d/default.conf

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

EXPOSE 80 443 5173

CMD ["sh", "-c", "npm run dev -- --host 0.0.0.0 & nginx -g 'daemon off;'"]
