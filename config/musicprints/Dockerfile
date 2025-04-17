FROM node:18-alpine

WORKDIR /app

COPY . .

ENV DEBIAN_FRONTEND=noninteractive

RUN apk add --no-cache build-base vips-dev zlib-dev libjpeg-turbo-dev libpng-dev libwebp-dev libheif-dev gcc g++ make python3 git libc6-compat cairo-dev pango-dev jpeg-dev giflib-dev librsvg-dev gcompat

RUN git clone https://repo.conputer.org/carlospineda/musicprints

WORKDIR /app/musicprints

RUN mkdir -p server/uploads

RUN npm i

EXPOSE 5000

CMD ["node", "server/index.js"]
