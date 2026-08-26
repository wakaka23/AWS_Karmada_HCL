# AWS_Karmada_HCL

Profile: first, second
Terrafom init: terraform init -backend-config=dev.tfbackend

## Common Setup

### Preparation
Ref: https://kubernetes.io/ja/docs/setup/production-environment/container-runtimes/#container-runtimes

--- Update apt packages ---
``` 
sudo apt-get update
```

--- Install containerd ---
```
sudo apt-get install -y containerd
sudo systemctl status containerd
sudo mkdir -p /etc/containerd
sudo sh -c 'containerd config default > /etc/containerd/config.toml'
```

--- Enable SystemdCgroup ---
```
sudo containerd config dump | grep SystemdCgroup
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl status containerd
```

--- Enable IPv4 forwarding ---
```
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system
```

### Install kubeadm, kubelet, kubectl
Ref: https://kubernetes.io/ja/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

--- Install packages needed to use the Kubernetes apt repository ---
```
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
```

--- Download GPG key ---
```
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.36/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

--- Add k8s apt repository ---
```
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.36/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

--- Install kubeadm,kubelet,kubectl ---
```
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl daemon-reload
sudo systemctl enable --now kubelet.service
```

## ControlPlane Setup

### Initialize Cluster
Ref: https://kubernetes.io/ja/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/

```
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --service-cidr=172.16.0.0/12
mkdir -p ~/.kube
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
```

### Install Calico
Ref: https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart

```
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.32.1/manifests/v1_crd_projectcalico_org.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.32.1/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.32.1/manifests/custom-resources.yaml
```

### Prepare Join Command
```
kubeadm token create --print-join-command
```

## WorkerNode setup

## Join Cluster
```
sudo kubeadm join <ControlPlane IP>:6443 --token <Token> --discovery-token-ca-cert-hash sha256:<Hash>
systemctl status kubelet
```
