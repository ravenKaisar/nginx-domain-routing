FROM mysql:8.0

COPY ./init_data.sql /tmp

CMD [ "mysqld", "--init-file=/tmp/init_data.sql" ]