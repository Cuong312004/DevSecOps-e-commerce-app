# 🧪 Tutorial: Triển khai hệ thống DevSecOps E-commerce Microservices trên Azure

Một hệ thống Microservices hoàn chỉnh, tích hợp CI/CD, GitOps, Monitoring và DevSecOps gồm các thành phần:

- **Kubernetes (AKS)**
- **Jenkins CI + Docker + ACR**
- **ArgoCD (GitOps)**
- **Prometheus + Grafana (Monitoring)**
- **SonarQube (Static Code Analysis)**
- **IaC với Terraform + bảo mật Checkov**
![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/1.png)
---

## 1️⃣ Triển khai hạ tầng với Terraform và Checkov

```bash
cd terraform/envs/staging

# Quét bảo mật với Checkov
checkov -d .

# Khởi tạo và áp dụng Terraform
terraform init
terraform plan
terraform apply
```

---

## 2️⃣ Kết nối tới cụm AKS & cấp quyền ACR

```bash
az aks get-credentials --resource-group rg-staging --name staging-aks
az aks update --name staging-aks --resource-group rg-staging --attach-acr stagingacr1234
```

---

## 3️⃣ Kiểm tra trạng thái các thành phần

```bash
kubectl get pods -n argocd                  # Kiểm tra ArgoCD
kubectl get svc -n ingress-nginx            # Kiểm tra Ingress Controller
```
![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/2.png)
---

## 4️⃣ Deploy các ứng dụng microservice với ArgoCD

```bash
kubectl apply -f argocd/apps/auth-service.yaml -n argocd
kubectl apply -f argocd/apps/product-service.yaml -n argocd
kubectl apply -f argocd/apps/order-service.yaml -n argocd
kubectl apply -f argocd/apps/frontend.yaml -n argocd
```
![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/3.png)
---

## 5️⃣ Cấu hình SonarQube

- Truy cập Azure > **Network Security Group**
  ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/4.png)
- Cho phép port `9000` ở cả `jenkins-nsg` và `staging-subnet-nsg`
  ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/5.png)
  ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/6.png)
- Truy cập: `http://<SonarQube_Public_IP>:9000`
- Đăng nhập: `admin / admin`
  ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/7.png)
- Vào `My Account > Security` → Tạo và lưu lại token

---

## 6️⃣ Cấu hình Jenkins

### Truy cập Jenkins VM

- Azure > Virtual Machines > `jenkins-staging-vm`
  ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/8.png)
- Kích hoạt Serial console 
  ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/9.png)
  ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/10.png)
- Enable `Serial Console` → Đăng nhập vào VM 
- Xem mật khẩu:
```bash
sudo nano /var/lib/jenkins/secrets/initialAdminPassword
```
  ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/11.png)
- Truy cập Jenkins: `http://<jenkins_public_ip>:8080`
- Đăng nhập và setup:
  - Install suggested plugins
    ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/12.png)
  - Tạo tài khoản đăng nhập
    ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/13.png)
### Cài plugin

- `Pipeline Utility Steps`
- `SonarQube Scanner`
  ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/14.png)
### Tạo Credential

- `github_cre`: cho repo code
  ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/15.png)
- `acr_cre`: từ ACR → Access Keys → admin user
- Tạo acr_cre: vào azure -> Container registries -> stagingacr1234 -> Access keys -> Chọn Admin user -> Lấy username password -> quay lại tạo credential jenkins
  ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/16.png)
  ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/17.png)
- `sonar_cre`: dùng token SonarQube
![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/18.png)
### Kết nối SonarQube

- Manage Jenkins > Configure System
- Add SonarQube server 
![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/19.png)
- Vào manage jenkins ->Tool -> Add SonarQube Scanner
![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/20.png)

### Tạo Job Pipeline

- Triggers: GitHub webhook
- Source: Git > repo code
- Branch: `main`
- Vào GitHub > Settings > Webhooks > nhập URL Jenkins
![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/21.png)
---

## 7️⃣ Cấu hình ArgoCD

### Lấy mật khẩu mặc định

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```
-	Sau đó vào web https://www.base64decode.org/ , nhập mật khẩu và lấy đoạn giải mã của mật khẩu 
![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/22.png)
### Port-forward giao diện ArgoCD

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

→ Truy cập `https://localhost:8080`  
→ Đăng nhập: `admin` + mật khẩu đã giải mã
![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/23.png)
### Kết nối GitOps Repo

- Vào Settings > Repositories
- Add repo: nhập GitHub user/pass hoặc token
  ![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/24.png)
- Kết nối thành công: `Successful`
![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/25.png)
---

## 8️⃣ Cấu hình Prometheus + Grafana

```bash
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80
```

→ Truy cập: `http://localhost:3000`  
→ Đăng nhập: `admin / admin123`
![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/26.png)
- Dashboard > Playlists > Create
![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/27.png)
- Add dashboards và Start playlist
![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/28.png)
![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/29.png)
---

## 9️⃣ Thực nghiệm toàn hệ thống

- Thay đổi nhỏ trong Jenkinsfile → push lên GitHub
- Jenkins bắt sự kiện → chạy pipeline:
![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/30.png)
  - SonarQube scan → Dashboard hiển thị chất lượng code
![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/31.png)
  - Build + push Docker image lên ACR
![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/32.png)
- ArgoCD tự động phát hiện thay đổi image → Sync
![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/33.png)
- Grafana hiển thị các chỉ số giám sát realtime
![System Architecture](https://github.com/Cuong312004/DevSecOps-e-commerce-app/blob/main/image/34.png)
---

## ✅ Kết quả cuối cùng

✔️ Một hệ thống DevSecOps hoàn chỉnh, tự động từ khâu code → build → scan → deploy → monitoring trên Azure.
