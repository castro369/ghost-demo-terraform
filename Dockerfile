#FROM ghost:alpine
#FROM ghost:latest
#COPY content/ /var/lib/ghost/content/
FROM ghost:4.20.4
#ENV database__connection__host=${DB_HOST}
#ENV database__connection__port=${DB_PORT}
#ENV database__connection__user=${DB_USER}
#ENV database__connection__password=${DB_PASS}
#ENV database__connection__database=${DB_NAME}


#ENV database__client=mysql
#ENV database__connection__host=127.0.0.1
#ENV database__connection__port=3306
#ENV database__connection__user=ghost
#ENV database__connection__password=123qwe
#ENV database__connection__database=ghost
