FROM nginx:1.18-alpine
COPY index.html /app/
COPY conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx","-g","daemon off;"]
