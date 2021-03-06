FROM node:13-alpine as build
RUN mkdir -p /app
WORKDIR /app
ENV CYPRESS_INSTALL_BINARY=0
COPY package.json yarn.lock .yarnrc.yml /app/
COPY .yarn /app/.yarn
RUN yarn --immutable
ENV NODE_ENV=production
ENV PROD_ONLY=true
COPY src  /app/src/
COPY public /app/public/
COPY scripts /app/scripts/
COPY webpack.config.js .babelrc.js .babelrc.server.js /app/
RUN yarn build
RUN node scripts/checkAssetFiles.js


FROM node:13-alpine as app
RUN yarn global add modclean
RUN mkdir -p /app
WORKDIR /app
COPY package.json yarn.lock .yarnrc.yml /app/
COPY .yarn /app/.yarn
RUN NODE_ENV=production yarn --immutable
RUN modclean -r -a '*.ts|*.tsx' -I 'example*'
RUN rm -rf .yarn .yarnrc.yml
COPY docs /app/docs/
COPY --from=build /app/dist/ /app/dist/

FROM node:13-alpine
ENV NODE_ENV=production
ENV TZ=Europe/Berlin
USER node
WORKDIR /app
COPY --from=app /app /app
CMD [ "node", "dist/server/server/index.js" ]
