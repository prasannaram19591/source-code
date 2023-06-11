cd
#yum update -y
swapoff -a
systemctl stop firewalld
systemctl disable firewalld
yum install epel-release -y
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
dnf install docker-ce --nobest -y
systemctl enable --now docker
dnf install conntrack -y
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl
cp /usr/local/bin/kubectl /usr/local/sbin/kubectl
kubectl version
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube
mkdir -p /usr/local/bin/
install minikube /usr/local/bin/
mv minikube /usr/local/sbin
minikube version
yum install -y git
git clone https://github.com/Mirantis/cri-dockerd.git
curl -Lo installer_linux https://storage.googleapis.com/golang/getgo/installer_linux
chmod +x ./installer_linux
./installer_linux
source /root/.bash_profile
cd cri-dockerd
mkdir bin
go build -o bin/cri-dockerd
install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd
cp -a packaging/systemd/* /etc/systemd/system
sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
cp /usr/local/bin/cri-dockerd /usr/local/sbin/cri-dockerd
systemctl daemon-reload
systemctl enable --now cri-docker.socket
systemctl is-active cri-docker.socket
cd
git clone https://github.com/prasannaram19591/source-code.git
cd /root/source-code/minikube/
cp *.repo /etc/yum.repos.d/
yum install cri-o cri-tools -y
systemctl enable --now crio
systemctl is-enabled crio
cd
\cp /usr/local/bin/cri-dockerd .
minikube start --driver=none
minikube status
kubectl cluster-info
kubectl get nodes
systemctl enable --now kubelet cri-docker
systemctl is-active docker crio kubelet cri-docker
systemctl is-enabled docker crio kubelet cri-docker
kubectl taint nodes $(hostname) node.kubernetes.io/not-ready-
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
