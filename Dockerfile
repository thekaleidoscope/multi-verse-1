FROM node:20-alpine


RUN addgroup --system --gid 1001 app-services && adduser --system --uid 1001 nonroot app-services
USER nonroot

WORKDIR /app
COPY --link . .

RUN npm ci
RUN npm run build

CMD ["sh", "-c", "node ./dist/index.js && tail -f /dev/null"]
