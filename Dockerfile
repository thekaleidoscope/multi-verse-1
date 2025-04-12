FROM node:20-alpine

WORKDIR /app
COPY --link . .

RUN addgroup --system --gid 1001 app-services && adduser --system --uid 1001 nonroot app-services
USER nonroot

RUN npm ci
RUN npm run build

CMD sh -c 'node ./dist/server.js'
