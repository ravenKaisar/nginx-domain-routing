FROM node:18-alpine

WORKDIR /api

COPY services/api /api

RUN yarn install

EXPOSE 8000

CMD [ "node", "server.js" ]