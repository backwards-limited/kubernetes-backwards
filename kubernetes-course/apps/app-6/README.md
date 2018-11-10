# ConfigMap

If you don't have a **secret**, pop it into a **ConfigMap** instead.

ConfigMap key/value pair can be read by your application using:

- Environment variables

- Container command line arguments in pod configuration

- Volumes

  Could be a full configuration file mounted using a volume

Example of generating ConfigMap from a file:

```bash
kubectl create configmap app-config --from-file=app.properties
```

where app.properties:

```properties
driver = jdbc
database = postgres
```

So, using environment variables:

```yaml
...
spec:
  containers:
    - name: my-app
      env:
        - name: DRIVER
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: driver
```

Or using a volume:

```yaml
...
spec:
  containers:
    - name: my-app
      volumeMounts:
        - name: config-volume
          mountPath: /etc/config
  volumes:
    - name: config-volume
      configMap:
        name: app-config
```

## Example

```mermaid
graph LR
config -->|Inject into|NGINX
NGINX --> WebApp[Web App]
WebApp --> Database
```

```bash
$ minikube start

$ kubectl create configmap nginx-config --from-file=reverse-proxy.conf
configmap "nginx-config" created

$ kubectl get configmaps
NAME           DATA      AGE
nginx-config   1         45s

$ kubectl get configmap nginx-config -o yaml
apiVersion: v1
data:
  reverse-proxy.conf: ...
  
$ kubectl create -f nginx.yml
pod "nginx" created

$ kubectl create -f nginx-service.yml
service "nginx-service" created  
```

And let's see if all checks out:

```bash
$ http $(minikube service nginx-service --url) -v
GET / HTTP/1.1
Accept: */*
Accept-Encoding: gzip, deflate
Connection: keep-alive
Host: 192.168.99.100:32352
User-Agent: HTTPie/1.0.0

HTTP/1.1 200 OK
Connection: keep-alive
Content-Length: 12
Content-Type: text/html; charset=utf-8
Date: Sat, 10 Nov 2018 14:18:27 GMT
ETag: W/"c-Lve95gjOVATpfV8EL5X4nxwjKHE"
Server: nginx/1.11.13
X-Powered-By: Express

Hello World!
```

```bash
$ kubectl exec -it nginx -c nginx -- bash
```

```basic
root@nginx:/# ps x
  PID TTY      STAT   TIME COMMAND
    1 ?        Ss     0:00 nginx: master process nginx -g daemon off;
    6 pts/0    Ss     0:00 bash
   11 pts/0    R+     0:00 ps x

root@nginx:/# ls -las /etc/nginx/conf.d
total 12
4 drwxrwxrwx 3 root root 4096 Nov 10 14:13 .
4 drwxr-xr-x 3 root root 4096 Apr  6  2017 ..
4 drwxr-xr-x 2 root root 4096 Nov 10 14:13 ..2018_11_10_14_13_00.420582454
0 lrwxrwxrwx 1 root root   31 Nov 10 14:13 ..data -> ..2018_11_10_14_13_00.420582454
0 lrwxrwxrwx 1 root root   25 Nov 10 14:13 reverse-proxy.conf -> ..data/reverse-proxy.conf

root@nginx:/# more /etc/nginx/conf.d/reverse-proxy.conf
server {
  listen       80;
  server_name  localhost;

  location / {
    proxy_bind 127.0.0.1;
    proxy_pass http://127.0.0.1:3000;
  }

  error_page   500 502 503 504  /50x.html;
  location = /50x.html {
    root   /usr/share/nginx/html;
  }
}
```

