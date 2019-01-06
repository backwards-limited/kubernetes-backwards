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

## Docker Compose

> ![Docker compose plan](docs/images/docker-compose-plan.png)

[docker-compose.yml][docker-compose.yml]

## Nginx Path Routing

Within configurations, we shall refer to the **React server** as **client** as provides the client frontend such as web pages. And we shall refer to the **Express server** as **api**.

> ![Nginx path routing](docs/images/nginx-path-routing.png)

> ![Nginx](docs/images/nginx.png)

> ![Nginx configuration](docs/images/nginx-configuration.png)

We have the following [default.conf](nginx/default.conf):

```nginx
upstream client {
  server client:3000;
}

upstream api {
  server api:5000;
}

server {
  listen 80;

  location / {
    proxy_pass http://client;
  }

  location /api {
    rewrite /api/(.*) /$1 break;
    proxy_pass http://api;
  }
}
```

and we want to apply this to a new nginx docker image.

## Boot (Test)

First time:

```bash
$ docker-compose up --build
```

Next time:

```bash
$ docker-compose up
```

Open up browser at [localhost:3050](http://localhost:3050):

> ![Initial UI](docs/images/initial-ui.png)

Notice we have right clicked the screen so that we can select **Inspect** upon which we shall see an error in the **Console**:

> ![Inspect](docs/images/inspect.png)

We need an extra configuration for React (in development mode).

## Opening Websocket Connection

React expects an open websocket connection to push through notifications. However, we have **nginx** proxied between the browser and the client/frontend, and so we have to configure this. Note the **sockjs-node** error in the **Console** to be added to [default.conf](nginx/default.conf):

```nginx
upstream client {
  server client:3000;
}

upstream api {
  server api:5000;
}

server {
  listen 80;

  location / {
    proxy_pass http://client;
  }

  location /sockjs-node {
    proxy_pass http://client;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "Upgrade";
  }

  location /api {
    rewrite /api/(.*) /$1 break;
    proxy_pass http://api;
  }
}
```

and we'll have to rebuild:

```bash
$ docker-compose up --build
```

## Workflow to AWS

> ![Workflow to AWS](docs/images/workflow-to-aws.png)

> ![Production](docs/images/production.png)

```bash
$ git init
$ git add .
$ git commit -m "Initial"
```

> ![Github new repo](docs/images/github-new-repo.png)

Once the repository is created:

```bash
$ git remote add origin https://github.com/davidainslie/multi-docker.git
$ git push -u origin master
```

Next we need a link between Github and Travis CI.

> ![Travis plan](docs/images/travis-plan.png)

As part of the [.travis.yml](.travis.yml) we need environment variables in [travis](https://travis-ci.com) for [docker hub](https://hub.docker.com) credentials.

> ![Travis env](docs/images/travis-env.png)

and we add our docker hub credentials:

> ![Travis dockerhub credentials](docs/images/travis-docker-credentials.png)

So we have a CI that pulls the repository from Github, builds some images and pushes them to Docker Hub. How do we deploy onto AWS?

> ![Multiple containers for AWS](docs/images/multi-containers-for-aws.png)

Elastic Beanstalk can handle one Dockerfile, it will automatically build and run. But when multiple Dockerfiles are involved, EB can't just randomly select one!

Let's create some instruction for EB with [Dockerrun.aws.json](Dockerrun.aws.json). The idea is similar to a **docker-compose.yml**, with slightly different jargon, e.g. instead of **Services** our new file will describe **Container Definitions**.

> ![AWS EB tasks](docs/images/aws-eb-tasks.png)

Take a look at [Amazon ECS Task Definitions](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html). What we write in **Dockerrun.aws.json** is defined under [Container Definitions](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#container_definitions).

With this new file we have to set up our environment on AWS:

> ![Elastic beanstalk](docs/images/eb.png)

> ![Create environment](docs/images/eb-create-environment.png)

> ![Environment tier](docs/images/environment-tier.png)

> ![Create environment](docs/images/create-environment.png)

> ![AWS EB](docs/images/aws-eb.png)

> ![AWS elastic cache](docs/images/aws-elastic-cache.png)

> ![AWS RDS](docs/images/aws-rds.png)

## AWS Sidetrack Regarding Required Services

> ![AWS Default](docs/images/aws-default.png)

> ![AWS VPC](docs/images/aws-vpc.png)

> ![AWS VPC search](docs/images/vpc-search.png)

> ![VPC](docs/images/vpc.png)

To have our services in Elastic Beanstalk talk to "other" services such as the managed Redis, we need a **security group** (a fancy name for **firewall rules**):

> ![Security group](docs/images/security-group.png)

Anything can connect to services on our EB instance via port 80.

And we can set up our own rules e.g. "allow traffic on port 3010 from IP 172.0.40.2".

To look up the security group...

> ![Navigate security group](docs/images/navigate-security-group.png)

> ![View security group](docs/images/view-security-group.png)

And so how do we allow our EB to communicate with Redis and Postgres? We add a firewall rule:

**Allow any traffic from any other AWS service that has this security group**.

> ![New firewall rule](docs/images/new-firewall-rule.png)

So let's create postgres, redis and a security group to be applied to all the above so that they can communicate.

## RDS

> ![Navigate to RDS](docs/images/navigate-rds.png)

> ![Start create database](docs/images/start-create-database.png)

> ![Creating Postgres](docs/images/creating-postgres.png)

> ![Postgres settings](docs/images/postgres-settings.png)

> ![Database options](docs/images/database-options.png)

## ElastiCache

> ![Navigate Elasticache](docs/images/navigate-elasticache.png)

> ![Choose Redis](docs/images/choose-redis.png)

> ![Choose create Redis](docs/images/choose-create-redis.png)

> ![Redis settings](docs/images/redis-settings.png)

> ![Redis node](docs/images/redis-node-type.png)

and we should go for **0** replicas.

> ![Redis advanced settings](docs/images/redis-advanced-settings.png)

## Custom Security Group (to wire all instances together)

Back on the VPC dashboard:

> ![Select security groups](docs/images/select-security-groups.png)

> ![Choose create security group](docs/images/choose-create-security-group.png)

> ![Create security group](docs/images/create-security-group.png)

> ![New security group](docs/images/new-security-group.png)

> ![Security group rule](docs/images/security-group-rule.png)

Now we have to assigned this configured security group to our 3 services.

## Apply Security Group to Resources

Add the new security group onto Redis:

> ![Modifying Redis](docs/images/modifying-redis.png)

> ![Redis modify](docs/images/modify-redis.png)

Next add the new security group to RDS:

> ![Modifying Postgres](docs/images/modifying-postgres.png)

> ![Modified Postgres](docs/images/modified-postgres.png)

and now for Elastic Beanstalk:

> ![Modifying EB](docs/images/modifying-eb.png)

> ![Mofified EB](docs/images/modified-eb.png)

## Environment Variables

Choosing our Elastic Beanstalk instance, then:

> ![Creating environment variables](docs/images/creating-environment-variables.png)

To add the **Redis host** environment variable, we have to look up:

> ![Check Elasticache](docs/images/check-elasticache.png)

> ![Redis host](docs/images/redis-host.png)

To add the **Postgres host** environment variable, we have to look up:

> ![RDS host lookup](docs/images/rds-host-lookup.png)

> ![RDS host lookup](docs/images/rds-host-lookup-2.png)

> ![RDS host](docs/images/rds-host.png)

> ![Environment variables](docs/images/environment-variables.png)

## IAM Keys for Deployment

Now Elastic Beanstalk only really needs the [Dockerrun.aws.json](Dockerrun.aws.json) file which it reads and pulls in all images declared in said file.

Let's create a new **user** with deployment access:

> ![Start user creation](docs/images/start-user-creation.png)

> ![Adding user](docs/images/adding-user.png)

> ![Add user](docs/images/add-user.png)

> ![Attaching policy](docs/images/attaching-policy.png)

> ![Beanstalk policy](docs/images/beanstalk-policy.png)

We'll copy the generate keys to Travis.

> ![Travis](docs/images/travis.png)

> ![Travis environment variables](docs/images/travis-environment-variables.png)

## Travis Deploy

Finally we can add **deploy** to [.travis.yml](.travis.yml). Note, we'll need to look up the **bucket name**:

> ![Bucket](docs/images/s3-bucket.png)

## Test Deployment

If there are any errors, check out the logs:

> ![Check logs](docs/images/check-logs.png)

> ![Logs](docs/images/logs.png)

To view our application click the generated link:

> ![Click link](docs/images/click-link.png)

## Teardown Resources

Teardown Elastic Beanstalk instance:

> ![Delete EB](docs/images/delete-eb.png)

Next we'll teardown the RDS instance:

> ![Teardown RDS](docs/images/teardown-rds.png)

> ![Confirm delete RDS](docs/images/confirm-delete-rds.png)

And teardown Elasticache:

> ![Teardown Redis](docs/images/teardown-redis.png)

Finally, we can remove the security group we set up for these services:

> ![Delete security groups](docs/images/delete-security-groups.png)

And just to be ultra efficient, let's remove the IAM keys we set up:

> ![Delete user](docs/images/delete-user.png)