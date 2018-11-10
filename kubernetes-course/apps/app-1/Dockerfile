FROM node:8.9.4

WORKDIR /app

ADD . /app

RUN \
  cd /app && \
  npm install

EXPOSE 3000

CMD npm start