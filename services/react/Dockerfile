FROM node:18-alpine

WORKDIR /app

COPY services/react /app

RUN yarn install
RUN yarn build

ENV NODE_ENV production

EXPOSE 3000

CMD [ "npx", "serve", "build" ]