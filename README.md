# nginx-simple-auth

Simple authenticating by Nginx

http://localhost:9999

---

This is adopt `RFC 2617 Digest Authentication`, it can't kick client due to browser cache when session timeout. But after browser cache flush(normally `300 sec`) you can try it again. You can check the access log under `nginx/logs/`.

About HTTP Authentication:

- Basic: RFC 2617 (1999) -> RFC 7617 (2015)

  **問題:**

  - Server只能確認帳號密碼，無法控制例如登入時效（session），只能靠browser的cookie expiration
  - Attacker可以Decode header並得到username和password
  - Replay attack

- Digest: RFC 2069 (1997) -> RFC 2617 (1999) -> RFC 7617 (2015)

  **好處:**

  - 可以加入其他資訊，如URI可以控制File-level的存取
  - 加入Nonce，防止了Chosen plaintext attack和Replay attack

  **問題:**

  - 要先取得nonce，所以需要多一個Request
  - Server依然不能控制user session

- OAuth 1.0 (Twitter, 2007)
- OAuth 2.0 (2012)
- Bearer (OAuth 2.0): RFC 6750 (2012)
- JSON Web Tokens (JWT): RFC 7519 (2015)

Ref:

- [MDN - HTTP authentication](https://developer.mozilla.org/en-US/docs/Web/HTTP/Authentication)
- [開發者必備知識 - HTTP認證（HTTP Authentication）](https://carsonwah.github.io/http-authentication.htmlhttps://carsonwah.github.io/http-authentication.html)
## 1. Compiling nginx static module from source code

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

### Troubleshooting on macOS

Install automake and autoconf on your Unix.

```sh
brew install autoconf automake libtool pcre 
```

if `xcrun: error: invalid active developer path (/Library/Developer/CommandLineTools), missing xcrun at: /Library/Developer/CommandLineTools/usr/bin/xcrun`

```sh
xcode-select --install
```

### Troubleshooting on ubuntu

```sh
apt-get update && apt-get upgrade -y
apt-get install curl zip -y

apt-get install libtool build-essential libpcre3 libpcre3-dev zlib1g-dev -y 

# setup as service 
curl -L -o init-deb.sh https://www.linode.com/docs/assets/660-init-deb.sh
mv init-deb.sh /etc/init.d/nginx
chmod +x /etc/init.d/nginx
/usr/sbin/update-rc.d -f nginx defaults
service nginx stop 

# check version
service nginx -V
```

## 2. setup nginx-http-auth-digest

### nginx config

```sh
#user  nobody;
worker_processes  1;

events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;


    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    #gzip  on;

    server {
        listen       80;
        server_name  localhost;

        auth_digest_user_file /usr/local/nginx/auth/passwd.digest;
        auth_digest_shm_size 4m;  
        
        location / {
            root   html;
            index  200.html index.html index.htm;

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

        error_page  401              /401.html;
        error_page  403              /403.html;
        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

    }

}
```

### Generate .giest

https://websistent.com/tools/htdigest-generator-tool/

Sample:

- Username:
  blackie
- Realm:
  This is not for you
- Password:
  pass.123

digest under auth/passwd.digest : `blackie:This is not for you:c9e9a18e180b9c2097c66ed4239195aa`

## 3. Start and stop Nginx

- Starting Nginx

    Assuming that nginx was configured to install to the default location of /usr/local/nginx…….

    ```sh
    sudo /usr/local/nginx/sbin/nginx
    ```

- Stopping Nginx

    Assuming that nginx was configured to install to the default location of /usr/local/nginx…….

    ```sh
    sudo /usr/local/nginx/sbin/nginx -s stop
    ```

## Launch Nginx via Dockerfile and docker-compose

```sh
# build image
docker build -t blackie/nginx-auth-digest:latest . 

# run container
docker-compose up
```

## Ref

- https://github.com/atomx/nginx-http-auth-digest