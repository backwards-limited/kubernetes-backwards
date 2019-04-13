# Nginx

The following is not necessary but we can install **nginx** on bare metal e.g. Mac:

```bash
➜ brew install nginx
...
==> Pouring nginx-1.15.11.mojave.bottle.tar.gz
==> Caveats
Docroot is: /usr/local/var/www

The default port has been set in /usr/local/etc/nginx/nginx.conf to 8080 so that
nginx can run without sudo.

nginx will load all files in /usr/local/etc/nginx/servers/.

To have launchd start nginx now and restart at login:
  brew services start nginx
Or, if you do not want/need a background service you can just run:
  nginx
```

To deploy **nginx** to our **kubernetes cluster on AWS**:

```bash
➜ kubectl create deployment my-nginx-deployment --image=nginx
```

```bash
➜ kubectl expose deployment my-nginx-deployment \
	--port=80 \
	--type=NodePort \
	--name=my-nginx-service
```

