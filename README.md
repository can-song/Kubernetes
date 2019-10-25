# Kubernetes

## 1.所有节点设置
### 1.1 运行install.sh进行如下操作
切换阿里云、关闭防火墙、关闭swap、配置docker源、关闭selinux
### 1.2 修改配置文件
#### 1.2.1永久关闭swap
~~~shell
vi /etc/fstab
~~~
注释swap行，禁止开机自动挂载

### 1.2.2 永久关闭selinux
~~~shell
vi /etc/systemfig/selinux
~~~
注释
~~~shell
SELINUX=disabled
~~~

## 2. 配置服务器
### 2.1 配置hosts文件
添加各个服务器的ip到/etc/hosts文件

### 2.2 搭建etcd


## 3. 安装kubernetes-master
~~~shell
vi /etc/kubernetes/apiserver
~~~
~~~code
KUBE_ETCD_SERVERS="--etcd-servers=http://master-ip:2379"
# Address range to use for services
KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=xxx.xxx.0.0/16"
~~~

## 参考文档
https://www.jianshu.com/p/ed10cf0f162d