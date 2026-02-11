FROM nginx:alpine

# 安装 openssl 用于生成自签名证书
RUN apk add --no-cache openssl

# 创建 SSL 证书目录
RUN mkdir -p /etc/nginx/ssl

# 生成自签名 SSL 证书（有效期 365 天，CN 可修改为你的域名）
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/private.key \
    -out /etc/nginx/ssl/certificate.crt \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=MyOrganization/OU=MyUnit/CN=localhost"

# 复制 Vue 构建产物
COPY dist /usr/share/nginx/html

# 自定义 nginx 配置：80 端口重定向到 443，443 端口启用 SSL 并提供静态文件
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
        root /usr/share/nginx/html; \
        index index.html index.htm; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

# 暴露 HTTPS（443）和 HTTP 重定向端口（80）
EXPOSE 80 443

# 前台运行 nginx
CMD ["nginx", "-g", "daemon off;"]
