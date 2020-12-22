# nginx-simple-auth

Simple authenticating by Nginx

## Launch Nginx via Docker

```shell
docker run --name my-nginx -p 9999:80 -v nginx/config/web.conf:/etc/nginx/conf.d/default.conf -v nginx/html:/usr/share/nginx/html:ro -d nginx
```
