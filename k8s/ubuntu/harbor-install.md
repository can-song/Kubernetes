# Harbor 安装

## 安装docker
略
## 安装docker-compose
```shell
apt install docker-compose
```
**附：**
其他安装方法
1. 官网
[地址](https://docs.docker.com/compose/install/#install-compose)
```shell
sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```
2. pip
```shell
pip install docker-compose
```

## 下载Harbor
[地址](https://github.com/goharbor/harbor/releases)
### 下载解压
```shell
wget https://storage.googleapis.com/harbor-releases/release-1.9.0/harbor-offline-installer-v1.9.2-rc1.tgz
tar -xzvf harbor*

```
### 修改配置文件harbor.cfg
```shell
cd harbar && vim harbor.yml
```
将hostname后面的地址改为本机ip地址
其他的信息自行配置
### 安装
```shell
# ./.prepare 
./install.sh
```

## 参考文档
https://blog.csdn.net/qq_35720307/article/details/86691752