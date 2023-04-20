FROM nginx

COPY nginx.conf /etc/nginx/nginx.conf
COPY wordpress.conf /etc/nginx/conf.d/wordpress.conf

EXPOSE 80
