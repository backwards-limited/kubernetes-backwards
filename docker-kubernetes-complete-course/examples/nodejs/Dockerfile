FROM node:alpine

WORKDIR /usr/app

COPY ./package.json ./

RUN npm install

# Upon making changes that do not involve dependencies, we want to avoid running the previous step
COPY ./ ./

CMD ["npm", "start"]