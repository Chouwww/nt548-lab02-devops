# Quản lý và triển khai hạ tầng AWS và ứng dụng microservices với Terraform, CloudFormation, GitHub Actions, AWS CodePipeline và Jenkins

**Môn học:** Công nghệ DevOps và Ứng dụng (NT548)  
**Trường:** Đại học Công nghệ Thông tin (UIT) - ĐHQG-HCM  
**Repository:** [Chouwww/nt548-lab02-devops](https://github.com/Chouwww/nt548-lab02-devops)

---

## 📖 Giới thiệu

Dự án này là bài thực hành Lab 02, tập trung vào việc tự động hóa triển khai hạ tầng đám mây (IaC) trên AWS và xây dựng luồng CI/CD hoàn chỉnh cho ứng dụng Microservices. Dự án được chia thành 3 nội dung chính:

1. Triển khai hạ tầng AWS bằng **Terraform** và tự động hóa kiểm tra bằng **GitHub Actions** (Checkov).
2. Triển khai hạ tầng AWS bằng **CloudFormation** và tự động hóa qua **AWS CodePipeline**.
3. Xây dựng luồng CI/CD với **Jenkins, SonarQube, Trivy** và triển khai ứng dụng lên cụm **Kubernetes (K3s)**.

---

## ⚙️ Yêu cầu môi trường (Prerequisites)

- Tài khoản AWS (hỗ trợ các dịch vụ VPC, EC2, CodePipeline).
- AWS CloudShell (sử dụng region `ap-southeast-1`).
- Tài khoản GitHub cá nhân và Docker Hub (VD: `hieulab03`).
- Đã tạo các Access Key của AWS để thiết lập GitHub Secrets.

---

## 🚀 Nội dung 1: Triển khai hạ tầng với Terraform & GitHub Actions

### 1. Cài đặt và Chạy mã nguồn

**Môi trường:** Thực hiện trên AWS CloudShell.

1. Clone repository về môi trường CloudShell:
   ```bash
   git clone [https://github.com/Chouwww/nt548-lab02-devops.git](https://github.com/Chouwww/nt548-lab02-devops.git)
   cd nt548-lab02-devops/terraform
   ```
2. Khởi tạo Terraform và áp dụng cấu hình:
   ```bash
   terraform init
   terraform validate
   terraform plan
   terraform apply -auto-approve
   ```

### 2. Kiểm tra kết quả

**Hạ tầng:** Sau khi chạy thành công, Terraform sẽ trả về các Output bao gồm vpc_id, public_subnet_id, private_subnet_id, nat_gateway_id và ec2_public_ip.
**Ứng dụng Web:** Truy cập trình duyệt hoặc dùng lệnh curl http://<ec2_public_ip>. Hệ thống sẽ trả về trang web với nội dung "NT548 Lab02 - Terraform EC2".
**CI/CD:** Truy cập tab Actions trên GitHub Repo. Sẽ thấy luồng "Terraform CI with Checkov" tự động chạy và quét bảo mật mã nguồn Terraform mỗi khi có commit mới.

---

## 🚀 Nội dung 2: Triển khai hạ tầng với CloudFormation & AWS CodePipeline

### 1. Cài đặt và Chạy mã nguồn

1. Repository CodeCommit lưu trữ mã nguồn là nt548-lab02-cfn-repo:
2. Clone repository từ GitHub và đẩy mã nguồn lên CodeCommit:
   ```bash
   git remote add codecommit [https://git-codecommit.ap-southeast-1.amazonaws.com/v1/repos/nt548-lab02-cfn-repo](https://git-codecommit.ap-southeast-1.amazonaws.com/v1/repos/nt548-lab02-cfn-repo)
   git push codecommit main
   ```
3. Pipeline được cấu hình với tên nt548-lab02-cfn-pipeline gồm 3 stage:
   Source: Trỏ đến CodeCommit repository
   Build: Trỏ đến CodeBuild project nt548-lab02-cfn-build (sử dụng file cloudformation/buildspec.yml để chạy cfn-lint và taskcat trên môi trường Python ảo).
   Deploy: Sử dụng CloudFormation để tạo hoặc cập nhật stack nt548-lab02-cfn-pipeline-stack.

### 2. Kiểm tra kết quả

1. Dùng lệnh aws codepipeline get-pipeline-state để kiểm tra Pipeline, trạng thái cần đạt Succeeded ở cả 3 bước (Source, Build, Deploy).
2. Truy cập curl http://<CFN_EC2_PUBLIC_IP> để kiểm tra web server (kết quả hiển thị: "NT548 Lab02 - CloudFormation EC2").

---

## 🚀 Nội dung 3: Tự động hóa CI/CD cho Microservices với Jenkins

### 1. Cài đặt môi trường máy chủ

**Môi trường:** Khởi tạo một máy ảo EC2 mới trên AWS (sử dụng hệ điều hành Ubuntu 24.04 LTS, cấu hình m7i-flex.large hoặc có thể là loại khác miễn sao đủ RAM để chạy Jenkins và SonarQube)

1. SSH vào máy ảo và thực thi các lệnh sau::

   ```bash
   sudo apt-get install -y docker.io docker-compose
   sudo chmod 666 /var/run/docker.sock

   curl -sfL [https://get.k3s.io](https://get.k3s.io) | sh -
   sudo chmod 644 /etc/rancher/k3s/k3s.yaml
   cp /etc/rancher/k3s/k3s.yaml ~/k3s-config.yaml.txt

   sudo sysctl -w vm.max_map_count=262144
   echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf

   ```

2. Khởi chạy và cấu hình CI/CD:
   Chạy Jenkins và SonarQube qua Docker Compose (dựa trên file docker-compose.yml):
   ```bash
   docker-compose up -d
   ```
   Cấu hình SonarQube (http://<EC2_IP>:9000):
   Tạo dự án với Project key nt548-microservice.  
    Tạo Token bảo mật nt548-jenkins-ci-token
   Cấu hình Jenkins (http://<EC2_IP>:8080):
   Tải file k3s-config.yaml.txt về, chỉnh sửa để kết nối cụm K3s.
   Thêm các credentials: sonar-token (Secret text), dockerhub-creds (Username with password), k8s-kubeconfig (Secret file).
   Cấu hình SonarQube Server trong hệ thống Jenkins.
   Tạo Pipeline:
   Tạo Item loại Pipeline, cấu hình Pipeline script from SCM trỏ về GitHub.
   Bật GitHub hook trigger for GITScm polling và thêm Webhook http://<EC2_IP>:8080/github-webhook/ trên GitHub.

### 2. Kiểm tra kết quả

**Kích hoạt tự động:**
Khi có commit mã nguồn đẩy lên GitHub, Webhook sẽ tự động kích hoạt Jenkins Pipeline.
**Luồng thực thi (theo Jenkinsfile):**
Checkout Code: Tải mã nguồn.
SonarQube Analysis: Quét chất lượng mã nguồn (Trạng thái: Passed).
Build Docker Image: Đóng gói ứng dụng.
Trivy Security Scan: Quét bảo mật Image mức HIGH và CRITICAL.
Push to Docker Hub: Đẩy Image lên registry.
Deploy to Kubernetes: Cập nhật tag mới và dùng kubectl apply lên K3s (kèm --insecure-skip-tls-verify).
**Thành quả:** Sau khi Pipeline báo Finished: SUCCESS, truy cập trình duyệt tại http://<EC2_Public_IP>:30080 để thấy ứng dụng web hiển thị "Hoan thanh Noi dung bai lab02!".
