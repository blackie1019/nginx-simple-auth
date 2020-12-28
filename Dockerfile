# 1. Compiling nginx module
# FROM ubuntu:21.04 as builder
FROM ubuntu:21.04 as builder
WORKDIR /tmp

# 更新
RUN apt-get update && apt-get upgrade -y

# 安裝檔案取得必要套件
RUN apt-get install curl zip -y

# 安裝建置環境必要套件
RUN apt-get install libtool build-essential libpcre3 libpcre3-dev zlib1g-dev -y 

# 下載 nginx & nginx-http-auth-digest
RUN curl -O http://nginx.org/download/nginx-1.19.6.tar.gz \
  && tar xvfz nginx-1.19.6.tar.gz \
  && curl -L -o nginx-http-auth-digest-master.zip https://github.com/atomx/nginx-http-auth-digest/archive/master.zip \
  && unzip nginx-http-auth-digest-master.zip

# 設定與編譯 nginx
RUN cd nginx-1.19.6 \
  && ./configure --add-module=../nginx-http-auth-digest-master \
  && make \
  && make install

# # 下載 init-deb.sh並設定開機預設服務
ENV PATH /usr/local/nginx/sbin:$PATH
# RUN cd /tmp && curl -L -o init-deb.sh https://www.linode.com/docs/assets/660-init-deb.sh && mv init-deb.sh /etc/init.d/nginx && chmod +x /etc/init.d/nginx && /usr/sbin/update-rc.d -f nginx defaults

# PORTS
EXPOSE 80
EXPOSE 443

# 啟動
CMD ["nginx", "-g", "daemon off;"]