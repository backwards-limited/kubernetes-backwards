# Kibana

![Kibana](images/kibana.png)

Even though we are using **fluentd** there is an index automatically generated that begins with **logstash** and today's date as a suffix (so we'd get a new index tomorrow with tomorrow's date).

![Index](images/index.png)

Fluentd with automatically add a timestamp for each log:

![With timestamp](images/index-with-timestamp.png)

---

​![Gathering logs](images/gathering-logs.png)

Click on **Discover** to access the *Kibana search engine* and we'll initially see *all logs*:

![All logs](images/all-logs.png)