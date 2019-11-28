# Kubernetes 安装
## 关闭交换分区
1. swapoff -a
2. 修改/etc/fstab，注释掉swap项
## 安装docker
略
## 安装apt-transport-https
```shell
apt update
apt install -y apt-transport-https
```
## 安装kubectl，kubelet，kubeadm
### 国内安装(本部分科学上网时也可以使用国外安装)
```shell
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add - 
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF  
apt-get update
apt-get install -y kubectl kubelet kubeadm 
```
### 国外安装

```shell
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
# 安装kubectl, kubelet, kubeadm
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt update
apt install -y kubectl kubelet kubeadm
```
## 初始化master节点并记录安装日志
```shell
kubeadm init \
--image-repository registry.aliyuncs.com/google_containers \
--pod-network-cidr=10.244.0.0/16 \
>kubeadm-init.log
```
日志文件中有以下两条信息会用到

1.主节点配置命令，加入以下信息才能使用kubectl命令
```shell
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```
2.工作节点加入集群命令

工作节点在上述配置完成后，执行如下命令就能加入集群
```
kubeadm join 10.160.65.100:6443 --token 6apcay.2duxw490c04g9b7i     --discovery-token-ca-cert-hash sha256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
**注：**
```
1.日志文件不幸遗失可以在master节点上使用 kubeadm token create --print-join-command 命令来重新生成
2.主节点配置失败可以执行重置操作后再安装：kubeadm reset
```

```m
参数：
--apiserver-advertise-address: k8s 中的主要服务apiserver的部署地址，填自己的管理节点 ip
--image-repository: 拉取的 docker 镜像源，因为初始化的时候kubeadm会去拉 k8s 的很多组件来进行部署，所以需要指定国内镜像源，下不然会拉取不到镜像。
--pod-network-cidr: 这个是 k8s 采用的节点网络，因为我们将要使用flannel作为 k8s 的网络，所以这里填10.244.0.0/16就好
--kubernetes-version: 这个是用来指定你要部署的 k8s 版本的，一般不用填，不过如果初始化过程中出现了因为版本不对导致的安装错误的话，可以用这个参数手动指定。
--ignore-preflight-errors: 忽略初始化时遇到的错误，比如说我想忽略 cpu 数量不够 2 核引起的错误，就可以用--ignore-preflight-errors=CpuNum。错误名称在初始化错误时会给出来。
```
## 安装flannel
```
wget https://raw.githubusercontent.com/coreos/flannel/a70459be0084506e4ec919aa1c114638878db11b/Documentation/kube-flannel.yml
kubectl apply -f kube-flannel.yml
```
安装失败可执行如下命令删除，然后到官网装最新的安装配置文件：[地址](https://github.com/coreos/flannel)
```shell
kubectl delete -f kube-flannel.yml
```
## 参考文档
https://www.jianshu.com/p/f2d4dd4d1fb1
https://www.cnblogs.com/alamisu/p/10751418.html