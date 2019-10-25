# su进入root模式
	# Primary workers:--------------------------------------------------------------------------------------------------------------------
host1$ nvidia-docker run -it \ 	
		--network=host \ 	# 网络配置同主机
		-v /mnt/share/ssh:/root/.ssh \ 	# 挂载本地ssh免密登录公钥路径到容器
		horovod:latest 	# 启动 nvidia-docker
	# 完整命令： nvidia-docker run -it --network=host -v /mnt/share/ssh:/root/.ssh horovod:latest
root@c278c88dd552:/examples# mpirun \ 	# 容器内运行mpirun
		-np 3 \ 	# 运行3个进程
		-H host1:1,host2:1,host3:1 \ 	# 每个主机允许的最大进程数
		-mca plm_rsh_args "-p 12345" \ 	# 默认配置及端口配置
		python keras_mnist_advanced.py 	# 运行训练脚本
	# 完整命令： mpirun -np 3 -H ai001:1,ai002:1,ai003:1 -mca plm_rsh_args "-p 12345" python keras_mnist_advanced.py
	# Secondary workers:------------------------------------------------------------------------------------------------------------
host2$ nvidia-docker run -it \ 	# 容器内运行mpirun
		--network=host \ 	# 网络配置同主机
		-v /mnt/share/ssh:/root/.ssh \ 	# 挂载本地ssh免密登录公钥路径到容器
		horovod:latest bash -c "/usr/sbin/sshd -p 12345; sleep infinity" 	# 运行horovod与相关网络配置
	# 完整命令： nvidia-docker run -it --network=host -v /mnt/share/ssh:/root/.ssh horovod:latest bash -c "/usr/sbin/sshd -p 12345; sleep infinity"
host3$ nvidia-docker run -it --network=host -v /mnt/share/ssh:/root/.ssh horovod:latest bash -c "/usr/sbin/sshd -p 12345; sleep infinity" 	# 配置host3同host2
