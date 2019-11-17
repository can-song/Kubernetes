# Harbor Install

* 系统初始化

防火墙设置等

* 安装docker

~~~shell
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager \
--add-repo \
http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum update -y && yum install -y docker-ce
## 创建 /etc/docker 目录
mkdir /etc/docker
# 配置 daemon.
cat > /etc/docker/daemon.json <<EOF
{"exec-opts": ["native.cgroupdriver=systemd"],
"log-driver": "json-file",
"log-opts": {"max-size": "100m"},
"insecure-registries":["https://hub.harbor.com"]}
EOF
mkdir -p /etc/systemd/system/docker.service.d
## 重启docker服务
systemctl daemon-reload && systemctl restart docker && systemctl enable docker
~~~

* 安装docker-compose
~~~shell
curl -L https://github.com/docker/compose/releases/download/1.9.0/docker-compose-`uname -s`-`uname -m`> /usr/local/bin/docker-compose
~~~

* 安装Harbor

官网：https://github.com/vmware/harbor/releases

    1 解压
    2 配置harbor.cfg

    简单起见，可以只修改hostname，即harbor的访问地址
    ######################################################################################
    hostname：目标的主机名或者完全限定域名
    ui_url_protocol：http或或https。默认为http
    db_password：用于db_auth的的MySQL数据库的根密码。更改此密码进行任何生产用途
    max_job_workers：（默认值为3）作业服务中的复制工作人员的最大数量。对于每个映像复制作业，工作人员将存储库的所有标签同步到远程目标。增加此数字允许系统中更多的并发复制作业。但是，由于每个工作人员都会消耗一定数量的网络/CPU/IO资源，请根据主机的硬件资源，仔细选择该属性的值
    customize_crt：（on或或off。默认为on）当此属性打开时，prepare脚本将为注册表的令牌的生成/验证创建私钥和根证书
    ssl_cert：SSL证书的路径，仅当协议设置为https时才应用
    ssl_cert_key：SSL密钥的路径，仅当协议设置为https时才应用
    secretkey_path：用于在复制策略中加密或解密远程注册表的密码的密钥路径
    ######################################################################################

* 创建https证书及配置

上一步harbor.cfg配置文件的默认证书路径配置如下
~~~shell
#The path of cert and key files for nginx, they are applied only the protocol is set to https
ssl_cert = /data/cert/server.crt
ssl_cert_key = /data/cert/server.key
~~~
新建目录
~~~shell
mkdir -p  /data/cert
chmod -R 777 /data/cert
~~~

~~~shell
# 生成秘钥
openssl genrsa -des3 -out server.key 2048
# 新建证书请求
openssl req -new -key server.key -out server.csr
# 备份私钥
cp server.key server.key.org
# 退出密码，避免认证失败
openssl rsa -in server.key.org -out server.key
# 添加签名
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
添加权限
chmod a+x *
~~~

* 执行脚本进行安装
~~~shell
#回到harbor根目录，执行install.sh脚本
./install.sh
~~~
在hosts文件中添加harbor的域名