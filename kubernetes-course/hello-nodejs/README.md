# Hello NodeJS Container Deployed to Kubernetes

```bash
$ docker build .
...
Successfully built 21b629e52df7

docker run -p 3000:3000 -t 21b629e52df7
```

```bash
$ curl localhost:3000
Hello NodeJS World
```