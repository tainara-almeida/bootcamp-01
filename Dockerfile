# Dockerfile

# Etapa 1: Build (neste caso, apenas copiando arquivos estáticos)
# Em um projeto React real, aqui você executaria `npm run build`
FROM busybox:latest as builder
WORKDIR /app
COPY ./app .

# Etapa 2: Servir os arquivos estáticos com Nginx
FROM nginx:1.23.3-alpine
COPY --from=builder /app /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
