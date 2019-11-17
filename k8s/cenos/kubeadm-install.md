# Kubeadm 安装Kubernetes
## 系统初始化

* 设置主机名，修改hosts文件
~~~shell
hostnamectl set-hostname k8s-master01
~~~

* 安装依赖包
~~~shell
yum install -y conntrack ntpdate ntp ipvsadm ipset jq iptables curl sysstat libseccomp wget vim net-tools git
~~~

* 设置防火墙
~~~shell
systemctl  stop firewalld  &&  systemctl  disable firewalld
yum -y install iptables-services  &&  systemctl  start iptables  &&  systemctl  enable iptables && iptables -F  &&  service iptables save
~~~

* 关闭SELINUX
~~~shell
swapoff -a && sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
setenforce 0 && sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
~~~

* 调整内核参数，优化
~~~shell
cat > kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
net.ipv4.tcp_tw_recycle=0
vm.swappiness=0 # 禁止使用 swap 空间，只有当系统 OOM 时才允许使用它
vm.overcommit_memory=1 # 不检查物理内存是否够用
vm.panic_on_oom=0 # 开启 OOM
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=1048576
fs.file-max=52706963fs.nr_open=52706963
net.ipv6.conf.all.disable_ipv6=1
net.netfilter.nf_conntrack_max=2310720
EOF
~~~

* 调整系统时区
~~~shell
# 设置系统时区为中国/上海
timedatectl set-timezone Asia/Shanghai
# 将当前的 UTC 时间写入硬件时钟
timedatectl set-local-rtc 0
# 重启依赖于系统时间的服务
systemctl restart rsyslog
systemctl restart crond
~~~

* 关闭系统不需要的服务
~~~shell
systemctl stop postfix && systemctl disable postfix
~~~

* 设置 rsyslogd 和 systemd journald
~~~shell
mkdir /var/log/journal # 持久化保存日志的目录
mkdir /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/99-prophet.conf <<EOF
[Journal]# 持久化保存到磁盘
Storage=persistent# 压缩历史日志
Compress=yes
SyncIntervalSec=5m
RateLimitInterval=30s
RateLimitBurst=1000# 最大占用空间 10G
SystemMaxUse=10G# 单日志文件最大 200M
SystemMaxFileSize=200M# 日志保存时间 2 周
MaxRetentionSec=2week# 不将日志转发到 syslog
ForwardToSyslog=no
EOF
systemctl restart systemd-journald
~~~

* 升级内核到4.44

CentOS 7.x 系统自带的 3.10.x 内核存在一些 Bugs，导致运行的 Docker、Kubernetes 不稳定，例如： rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
~~~shell
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
# 安装完成后检查 /boot/grub2/grub.cfg 中对应内核 menuentry 中是否包含 initrd16 配置，如果没有，再安装一次！
yum --enablerepo=elrepo-kernel install -y kernel-lt
# 设置开机从新内核启动
grub2-set-default 'CentOS Linux (4.4.189-1.el7.elrepo.x86_64) 7 (Core)'
~~~

## Kubeadm 安装
* kube-proxy开启ipvs的前置条件
~~~shell
modprobe br_netfilter
cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF
chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules &&lsmod | grep -e ip_vs -e nf_conntrack_ipv4
~~~

* 安装Docker软件
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
"log-opts": {"max-size": "100m"  }}
EOF
mkdir -p /etc/systemd/system/docker.service.d
## 重启docker服务
systemctl daemon-reload && systemctl restart docker && systemctl enable docker
~~~

* 安装kubeadm(主从配置)
~~~shell
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
yum -y  install  kubeadm-1.15.1 kubectl-1.15.1 kubelet-1.15.1
systemctl enable kubelet.service
~~~

* 初始化主节点
    1. 生成默认配置文件
    ~~~shell
    kubeadm config print init-defaults > kubeadm-config.yaml
    ~~~
    2. 编辑kubeadm-config.yaml
    ~~~shell
    vi kubeadm-config.yaml
    ~~~

        （1） 修改
        ~~~shell
        localAPIEndpoint:        
            advertiseAddress: 192.168.66.10    
        kubernetesVersion: v1.15.1
        networking:
            # 添加
            podSubnet: "10.244.0.0/16"
            # 保持不变
            # serviceSubnet: 10.96.0.0/12
        ~~~
        （2） 末尾追加
        ~~~shell
        ---
        apiVersion: kubeproxy.config.k8s.io/v1alpha1
        kind: KubeProxyConfiguration
        featureGates:
            SupportIPVSProxyMode: true
        mode: ipvs
        ~~~

    3. 初始化
    ~~~shell
    kubeadm init --config=kubeadm-config.yaml --experimental-upload-certs | tee kubeadm-init.log
    ~~~

* 加入主节点和工作节点
~~~shell
#安装日志中的加入命令
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
~~~

* 部署网络
~~~shell
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
~~~

* 添加工作节点
~~~shell
### 复制安装日志中的命令#######################################################
kubeadm join 192.168.66.11:6443 --token abcdef.0123456789abcdef \
    --discovery-token-ca-cert-hash sha256:931595729abdfb3a26d98182f9831e991c5b7f2328c01071a1e739026b77e6ec
#############################################################################
~~~