const express = require("express");
const redis = require("redis");
const process = require("process");

const app = express();

const client = redis.createClient({
  // Declared in docker-compose otherwise something like: http://my-redis.com
  host: "redis-server",
  port: 6379
});

client.set("hits", 0);

app.listen(8081, () => {
  console.log("Listening on port 8081");
});

app.get("/", (req, res) => {
  client.get("hits", (err, hits) => {
    var hitsUpdated = parseInt(hits) + 1;
    res.send("Number of hits: " + hitsUpdated);
    client.set("hits", hitsUpdated);
  });
});

app.get("/crash", (req, res) => {
  process.exit(1);
});