
#1.1切换阿里的yum源
#安装wget
yum install -y wget
#切换yum源
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
yum makecache
#安装网络工具
yum install -y net-tools

# 1.2关闭防火墙
systemctl stop firewalld & systemctl disable firewalld

# 1.3关闭swap
#临时关闭
swapoff -a
#永久关闭,重启后生效
#vi /etc/fstab
#注释以下代码

# 1.4 配置docker源
yum -y install yum-utils
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum makecache

# 1.5 关闭selinux
#获取状态
getenforce
#暂时关闭
setenforce 0
#永久关闭 需重启
#vi /etc/sysconfig/selinux
#注释以下代码