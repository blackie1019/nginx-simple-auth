# nginx-simple-auth

Simple authenticating by Nginx

## From source code

```sh
mkdir src&& cd src
curl -O http://nginx.org/download/nginx-1.19.6.tar.gz
tar xvfz nginx-1.19.6.tar.gz

curl -L -o nginx-http-auth-digest-master.zip https://github.com/atomx/nginx-http-auth-digest/archive/master.zip
unzip nginx-http-auth-digest-master.zip

cd nginx-1.19.6
./configure --add-module=../nginx-http-auth-digest-master
```

```sh
make && make install
```


### troubleshooting on macOS

Install automake and autoconf on your Unix.

```sh
brew install autoconf automake libtool pcre 
```

if `xcrun: error: invalid active developer path (/Library/Developer/CommandLineTools), missing xcrun at: /Library/Developer/CommandLineTools/usr/bin/xcrun`

```sh
xcode-select --install
```

### troubleshooting on ubuntu

```sh
apt-get update && apt-get upgrade -y
apt-get install curl zip -y

apt-get install libtool build-essential libpcre3 libpcre3-dev zlib1g-dev -y 

#check version
sudo /usr/local/nginx/sbin/nginx -V
```

### Config

```sh
#user  nobody;
worker_processes  1;

events {
    worker_connections  1024;
}


http {
    server {
        auth_digest_user_file /usr/local/nginx/auth/passwd.digest;
        auth_digest_shm_size 4m;   # the storage space allocated for tracking active sessions

        listen       80;
        server_name  localhost;

        location / {
            root   html;
            index  index.html index.htm;
            auth_digest 'This is not for you';
            auth_digest_timeout 30s; # allow users to wait 1 minute between receiving the
                                    # challenge and hitting send in the browser dialog box
            auth_digest_expires 10s; # after a successful challenge/response, let the client
                                    # continue to use the same nonce for additional requests
                                    # for 10 seconds before generating a new challenge
            auth_digest_replays 20;  # also generate a new challenge if the client uses the
                                     # same nonce more than 20 times before the expire time limit
            # The amount of time for which the server will ignore authentication requests from a client address once the number of failed authentications from that client reaches auth_digest_maxtries.
            auth_digest_evasion_time 60s;    
            # The number of failed authentication attempts from a client address before the module enters evasive tactics. For evasion purposes, only network clients are tracked, and only by address (not including port number). A successful authentication clears the counters.
            auth_digest_maxtries 5;

            # 於 Header 加入不需要 Cache 指令
            add_header Cache-Control no-cache;  
            add_header Cache-Control private;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
}

```
### Start and Stop Nginx

Starting Nginx
Assuming that nginx was configured to install to the default location of /usr/local/nginx…….

```sh
sudo /usr/local/nginx/sbin/nginx
```

Stopping Nginx
Assuming that nginx was configured to install to the default location of /usr/local/nginx…….

```sh
sudo /usr/local/nginx/sbin/nginx -s stop
```

### Generate .giest

https://websistent.com/tools/htdigest-generator-tool/

## Launch Nginx via Docker

```shell
docker run --name my-nginx -p 9999:80 -v /Users/blackie/Desktop/repo/nginx-simple-auth/nginx/config/default.conf:/etc/nginx/nginx.conf:ro -v /Users/blackie/Desktop/repo/nginx-simple-auth/nginx/html:/usr/share/nginx/html nginx

docker run --name my-nginx -p 9999:80 ubuntu:21.04

```

## module

https://github.com/atomx/nginx-http-auth-digest

## Run

```sh
# 精簡版的 docker 映像檔案(如 Alpine） 没有内置 bash 的。所以用 /bin/sh
docker exec -it {container sha} /bin/sh
```

## Ref

- https://blog.51cto.com/marvin89/2121017 