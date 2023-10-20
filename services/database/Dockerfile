FROM mysql:8.0

COPY services/database/init_data.sql /tmp

CMD [ "mysqld", "--init-file=/tmp/init_data.sql" ]