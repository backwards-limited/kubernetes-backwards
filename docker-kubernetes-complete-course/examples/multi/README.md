# Multi Container App Deployed to AWS

This application will be an **over the top** Fibonacci calculator.

> ![Fibonacci](docs/images/fib.png)

> ![Fibonacci UI](docs/images/fib-ui.png)

> ![Architecture](docs/images/architecture.png)

- Browser hits nginx which in turn hits the React server for the GUI.
- All API calls are routed to the Express server e.g. user submits *index* for Fibonacci calculation.

> ![Calculating](docs/images/calculating.png)

- All *seen* values are persisted in Postgres.
- Calculated values are cached in Redis.

> ![Fibonacci calculation](docs/images/calculation.png)

Most of the files related to the above are straightforward. Just a little extra is required for the **react app**.

Hopefully you already went through [Setup](../../../docs/setup.md), where you need the following:

```bash
$ npm install -g create-react-app
```

Now we can create the react app:

```bash
$ create-react-app client
...
Installing packages. This might take a couple of minutes.
...
```

## Dockerize for Dev

> ![Dockerize for dev](docs/images/dockerize-for-dev.png)

#### In "client" directory

```bash
$ docker build -f Dockerfile.dev -t davidainslie/multi-client .

$ docker run davidainslie/multi-client
```

#### In "server" directory

```bash
$ docker build -f Dockerfile.dev -t davidainslie/multi-server .

$ docker run davidainslie/multi-server
```

Initial run will result in an error because of missing containers to connect to.

#### In "worker" directory

```bash
$ docker build -f Dockerfile.dev -t davidainslie/multi-worker .

$ docker run davidainslie/multi-worker
```

