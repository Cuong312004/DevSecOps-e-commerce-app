# 🧪 Tutorial: Deploy a DevSecOps E-commerce Microservices System on Azure

A complete Microservices system with CI/CD, GitOps, Monitoring, and DevSecOps using:

- **Kubernetes (AKS)**
- **Jenkins CI + Docker + ACR**
- **ArgoCD (GitOps)**
- **Prometheus + Grafana (Monitoring)**
- **SonarQube (Static Code Analysis)**
- **IaC using Terraform + Security with Checkov**

![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/1.png)

---

## 🧾 Before You Begin: Create a `terraform.tfvars` file

In the folder `terraform/envs/staging`, create a file `terraform.tfvars` with the following variables:

```hcl
location              = "Your Azure region"
resource_group_name   = "Your resource group"
subscription_id       = "Your Azure subscription ID"
admin_username        = "jenkins-admin"            # Username for Jenkins VM
admin_password        = "yourStrongPasswordHere!"  # Password for Jenkins VM
public_key_path       = "~/.ssh/id_rsa.pub"        # SSH public key path created on Azure
```

## 1️⃣ Provision Infrastructure with Terraform and Checkov

```bash
cd terraform/envs/staging

# Run security scan with Checkov
checkov -d .

# Initialize and apply Terraform
terraform init
terraform plan
terraform apply
```

---

## 2️⃣ Connect to AKS Cluster & Attach ACR

```bash
az aks get-credentials --resource-group rg-staging --name staging-aks
az aks update --name staging-aks --resource-group rg-staging --attach-acr stagingacr1234
```

---

## 3️⃣ Check ArgoCD & Ingress Controller Status

```bash
kubectl get pods -n argocd                  # Kiểm tra ArgoCD
kubectl get svc -n ingress-nginx            # Kiểm tra Ingress Controller
```
![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/2.png)
---

## 4️⃣ Deploy Microservices with ArgoCD

```bash
kubectl apply -f argocd/apps/auth-service.yaml -n argocd
kubectl apply -f argocd/apps/product-service.yaml -n argocd
kubectl apply -f argocd/apps/order-service.yaml -n argocd
kubectl apply -f argocd/apps/frontend.yaml -n argocd
```
![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/3.png)
---

## 5️⃣ Configure SonarQube

- Go to Azure > Network Security Groups
  
  ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/4.png)

- Add inbound port `9000` for both `jenkins-nsg` and `staging-subnet-nsg`.

  ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/5.png)

  ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/6.png)

- Access `http://<SonarQube_Public_IP>:9000` 
- Login: `admin / admin`

  ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/7.png)

- Go to `My Account > Security` → generate and save a token

---

## 6️⃣ Configure Jenkins CI/CD

### Access Jenkins VM

- Azure > Virtual Machines > `jenkins-staging-vm`

  ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/8.png)

- Enable Serial Console access

  ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/9.png)

  ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/10.png)

- Login VM via serial console and retrieve initial password:
```bash
sudo nano /var/lib/jenkins/secrets/initialAdminPassword
```
  ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/11.png)

- Access Jenkins: `http://<jenkins_public_ip>:8080`
- Login và setup:
  - Install suggested plugins
  
    ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/12.png)
  
  - Create admin account
  
    ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/13.png)
  
### Install Plugins

- `Pipeline Utility Steps`
- `SonarQube Scanner`

  ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/14.png)

### Tạo Credential

- `github_cre`: cho repo code

  ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/15.png)

- `acr_cre` → ACR Access Keys (enable Admin user in Azure) -> take username password -> comeback to create credential jenkins

  ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/16.png)
  
  ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/17.png)

- `sonar_cre`: use token SonarQube

![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/18.png)

### Configure SonarQube Integration

- Manage Jenkins > Configure System
- Add SonarQube server

![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/19.png)

- Jenkins → Manage Jenkins → Global Tool Configuration → Add SonarQube Scanner

![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/20.png)

### Create Jenkins Job (Pipeline)

- Triggers: GitHub webhook
- Source: Git > repo code
- Branch: `main`
- Vào GitHub > Settings > Webhooks > nhập URL Jenkins

![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/21.png)
---

## 7️⃣ Configure ArgoCD

### Get ArgoCD Admin Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```
-	Access to web https://www.base64decode.org/ , add password and get decode password

![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/22.png)

### Port-forward ArgoCD UI

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

→ Access `https://localhost:8080`  
→ Login: `admin` + decode password

![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/23.png)

### Connect GitOps Repo

- ArgoCD UI → Settings → Repositories
- Add repo: Connect GitHub repo (via username/token)

  ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/24.png)
  
- Connect: `Successful`

![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/25.png)

---

## 8️⃣ Set Up Prometheus + Grafana

```bash
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80
```

→ Access: `http://localhost:3000`  
→ Login: `admin / admin123`

![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/26.png)

- Navigate: Dashboard → Playlists → Create

![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/27.png)

- Add dashboards và Start playlist

![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/28.png)

![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/29.png)

---

## 9️⃣ Test the Full Pipeline

- Modify and push code (e.g., Jenkinsfile)
- Jenkins triggers pipeline:

![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/30.png)

  - SonarQube scans code → result shown on dashboard

![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/31.png)

  - Jenkins builds and pushes Docker image to ACR

![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/32.png)

- ArgoCD syncs latest image to AKS

![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/33.png)

- Grafana displays monitoring metrics

![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/34.png)

---

## ✅ Final Result

✔️ A complete DevSecOps microservices pipeline running CI/CD, GitOps, monitoring, and security checks — fully automated on Azure.
