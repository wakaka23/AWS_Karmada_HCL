# AWS_Karmada_HCL
https://qiita.com/showchan33/items/02e4a5f02b08c08d7813

## Common Setup

### Preparation
--- Change hostname ---  
・https://dev.classmethod.jp/articles/ec2-al2023-set-static-hostname/
``` 
sudo hostnamectl set-hostname controlplane/node01
sudo vi /etc/cloud/cloud.cfg
-------------------------------
# 変更前
preserve_hostname: false

# 変更後
preserve_hostname: true
-------------------------------
```


--- Update apt packages ---
``` 
sudo apt-get update
```

--- Install containerd ---  
・CNIとしてContainerdをインストールする  
・Containerdのデフォルト設定内容を設定ファイルとしてconfig.tomlに書き出す  
・disable_pluginsにcriが含まれていないことを確認する  
・https://kubernetes.io/ja/docs/setup/production-environment/container-runtimes/#container-runtimes

```
sudo apt-get install -y containerd
sudo systemctl status containerd
sudo mkdir -p /etc/containerd
sudo sh -c 'containerd config default > /etc/containerd/config.toml'
sudo cat /etc/containerd/config.toml | grep disabled_plugins
```

--- Enable SystemdCgroup for Cgroup Driver---  
・Containerdのデフォルト設定である「SystemdCgroup=false」を「true」に変更する  
・設定変更後はContainerdを再起動する  
・https://kubernetes.io/ja/docs/tasks/administer-cluster/kubeadm/configure-cgroup-driver/#configuring-the-kubelet-cgroup-driver

```
sudo containerd config dump | grep SystemdCgroup
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl status containerd
```

--- Enable IPv4 forwarding ---  
・Node上に作成されるethとveth間の通信のためにnet.ipv4.ip_forward設定が必要
```
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system
```

### Install kubeadm, kubelet, kubectl
https://kubernetes.io/ja/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

--- Install packages needed to use the Kubernetes apt repository ---
```
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
```

--- Download GPG key ---
```
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.36/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

--- Add v1.36 kubernetes package repository ---  
・kubeadm,kubelet,kubectlを含むkubernetes関連の主要パッケージの特定バージョン用となるRepositoryを追加  
・ https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/
```
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.36/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

--- Install kubeadm,kubelet,kubectl ---  
・実際に最新版となるv1.36.xのkubeadm, kubelet, kubectlをインストールする  
・バージョンを固定する（apt-get upgrade実行時にも反映対象外となる）  
・kubeletの再起動が必要
```
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl daemon-reload
sudo systemctl enable --now kubelet.service
```

## Control Plane Setup

### Initialize Cluster
・kubeadm initによるクラスタ初期構築  
・CNIとしてCalicoを使用する場合、PodCidrはkubeadm init時 or Calico Installation CRで明示的に指定する必要がある  
・ServiceCidrはデフォルトでは10.96.0.0/12が使用されるが、重複を防ぐためにRFC1918単位で分割する  
・EC2用：10.0.0.0/18, Service CIDR用: 172.16.0.0/12, Pod Network CIDR用: 192.168.0.0/16  
・https://kubernetes.io/ja/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/

```
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --service-cidr=172.16.0.0/12
mkdir -p ~/.kube
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
```

### Install Calico
・CNIとしてCalicoを使用する  
・Calicoを構成するCRD及びOperator（Controller）を配備する  
・Installation, Apiserver, Goldmane, WhiskerというCRを作成することでcalico-system NameSpaceに作成されるPod群がCalicoの実体となる  
・https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart  
・https://qiita.com/haru_yama/items/30e96adde58ef197238d

```
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.32.1/manifests/v1_crd_projectcalico_org.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.32.1/manifests/tigera-operator.yaml

wget https://raw.githubusercontent.com/projectcalico/calico/v3.32.1/manifests/custom-resources.yaml
vi custom-resources.yaml
kubectl apply -f custom-resources.yaml
```

### Prepare Join Command
・Clusterに参加していないNodeは証明書を所有していない。両者が正しい相手と通信しようとしていることを認識するためにTokenを利用する。  
・https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-join/
```
kubeadm token create --print-join-command
```

## Worker Node setup

### Join Cluster
・kubeadm token createで取得したコマンドをWorkerNode側で実行する
```
sudo kubeadm join <ControlPlane IP>:6443 --token <Token> --discovery-token-ca-cert-hash sha256:<Hash>
systemctl status kubelet
```
