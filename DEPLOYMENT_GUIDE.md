# Guía Maestra para Desplegar un Sitio Estático con GitHub, Portainer y Cloudflare

**Objetivo:** Desplegar de manera fiable un sitio web estático (HTML/CSS/JS) desde un repositorio de GitHub a un servidor con Portainer, sirviéndolo a través de un túnel de Cloudflare.

**Estrategia Principal:** La solución se basa en construir una imagen de Docker personalizada, autocontenida y optimizada para la caché. Este método evita los frágiles errores de montaje de volúmenes y garantiza que el entorno de despliegue sea idéntico cada vez.

---

## Pasos a Seguir

Sigue estos tres pasos en orden para configurar el repositorio.

### Paso 1: Crear el `Dockerfile`

Este archivo es la receta para construir tu imagen. Créalo en la raíz del proyecto.

```Dockerfile
# 1. USAR IMAGEN BASE
# Empezar con una imagen oficial y ligera de Nginx.
FROM nginx:alpine

# 2. LIMPIAR CONFIGURACIÓN POR DEFECTO
# Eliminar el archivo de configuración por defecto de Nginx para evitar conflictos.
RUN rm /etc/nginx/conf.d/default.conf

# 3. COPIAR CONFIGURACIÓN PERSONALIZADA
# Copiar nuestro propio archivo de configuración de Nginx.
# Lo crearemos en el siguiente paso.
COPY nginx/app.conf /etc/nginx/conf.d/

# 4. COPIAR LOS ARCHIVOS DEL SITIO WEB
# Copiar todo el contenido estático al directorio web de Nginx.
# Asegúrate de incluir todas las carpetas necesarias (css, js, img, etc.).
COPY index.html /usr/share/nginx/html/
COPY css/ /usr/share/nginx/html/css/
COPY js/ /usr/share/nginx/html/js/
COPY img/ /usr/share/nginx/html/img/

# 5. EXPONER EL PUERTO INTERNO
# Indicar a Docker que el contenedor escuchará en el puerto 80.
EXPOSE 80

# 6. COMANDO DE INICIO
# El comando para iniciar el servidor Nginx en primer plano.
CMD ["nginx", "-g", "daemon off;"]
```

### Paso 2: Crear la Configuración de Nginx

Para evitar el error `403 Forbidden`, necesitas un archivo de configuración que le diga explícitamente a Nginx que sirva `index.html`.

1.  Crea una carpeta en la raíz del proyecto llamada `nginx`.
2.  Dentro de esa carpeta, crea un archivo llamado `app.conf`.

```nginx
# nginx/app.conf

server {
    # Nginx escuchará en el puerto 80 DENTRO del contenedor.
    listen 80;
    server_name localhost;

    # Directorio raíz donde se encuentran los archivos del sitio.
    root /usr/share/nginx/html;
    # El archivo a servir por defecto.
    index index.html;

    # Reglas para manejar las solicitudes.
    location / {
        # Intenta servir el archivo solicitado. Si no lo encuentra, devuelve un 404.
        try_files $uri $uri/ =404;
    }
}
```

### Paso 3: Crear el `docker-compose.yml`

Este es el archivo de orquestación que Portainer leerá. Define el servicio, cómo construirlo y cómo conectarlo a la red.

```yaml
# docker-compose.yml

services:
  website:
    # 1. CONSTRUIR DESDE DOCKERFILE
    # Le dice a Docker que construya una imagen usando el Dockerfile
    # en el directorio actual ('.').
    build: .
    container_name: mi-proyecto-web # Elige un nombre descriptivo

    # 2. MAPEADO DE PUERTOS
    # Mapea el PUERTO_HOST (externo) al puerto 80 (interno del contenedor).
    # ¡Ajusta el PUERTO_HOST si está ocupado!
    ports:
      - "9876:80" # Ejemplo: usa el puerto 9876 en el host

    # 3. POLÍTICA DE REINICIO
    # Asegura que el contenedor se reinicie si se cae o tras reiniciar el servidor.
    restart: unless-stopped

    # 4. CONEXIÓN A LA RED DE CLOUDFLARE
    # Conecta este contenedor a una red existente llamada 'cloudflared'.
    networks:
      - cloudflared

# Declara que la red 'cloudflared' es externa y ya existe en Docker.
networks:
  cloudflared:
    external: true
```

---

## Guía de Despliegue y Troubleshooting

1.  **Commit y Push:** Guarda todos los archivos nuevos (`Dockerfile`, `nginx/app.conf`, `docker-compose.yml`) en tu repositorio de Git.
2.  **Despliegue en Portainer:** Ve a "Stacks", selecciona tu repositorio de Git y haz clic en "Update the stack" (o "Deploy the stack" si es la primera vez).
3.  **Error "Port is already allocated":** Si el despliegue falla con este error, significa que el puerto que elegiste en `ports` (ej: `9876`) ya está en uso en tu servidor. Simplemente elige otro número de puerto en tu `docker-compose.yml`, haz `commit/push` y vuelve a desplegar.
4.  **Configuración del Túnel de Cloudflare:** En tu panel de control de Cloudflare, asegúrate de que el servicio de tu túnel apunta a la dirección y puerto correctos en el servidor. Ejemplo: `http://localhost:9876`.
5.  **Caché de Docker:** La primera vez, Portainer construirá la imagen completa. En despliegues futuros, si solo cambias el `index.html`, Docker reutilizará la mayor parte de las capas cacheadas y el proceso será mucho más rápido. 