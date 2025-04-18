FROM node:18-bookworm

WORKDIR /app

COPY . .

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y build-essential libvips-dev zlib1g-dev libpng-dev libwebp-dev libheif-dev gcc g++ make python3 git libcairo2-dev libpango1.0-dev libgif-dev librsvg2-dev 

RUN git clone https://github.com/pineedaa/musicprints

WORKDIR /app/musicprints

RUN mkdir -p server/uploads

RUN npm i

EXPOSE 5000

CMD ["node", "server/index.js"]
