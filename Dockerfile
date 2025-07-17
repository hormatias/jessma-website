# Usar la imagen oficial de Nginx como base
FROM nginx:alpine

# Eliminar la configuración por defecto de Nginx para evitar conflictos
RUN rm /etc/nginx/conf.d/default.conf

# Copiar nuestro archivo de configuración personalizado de Nginx
COPY nginx/jessma.conf /etc/nginx/conf.d/

# Copiar el contenido estático del sitio web al directorio de Nginx
COPY index.html /usr/share/nginx/html/
COPY css /usr/share/nginx/html/css/
COPY js /usr/share/nginx/html/js/
COPY img /usr/share/nginx/html/img/

# Exponer el puerto 80 para que el contenedor pueda recibir tráfico
EXPOSE 80

# Comando para iniciar Nginx cuando el contenedor arranque
CMD ["nginx", "-g", "daemon off;"] 