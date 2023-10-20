FROM node:18-alpine

RUN mkdir -p api
WORKDIR /api

COPY . /api

RUN yarn install

CMD [ "node", "server.js" ]