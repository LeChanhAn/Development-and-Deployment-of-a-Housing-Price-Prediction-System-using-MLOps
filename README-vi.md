*Đọc bằng ngôn ngữ khác: [English](README.md)*
# Development and Deployment of a Housing Price Prediction System using MLOps

## 👥 Thành viên nhóm

| Họ và tên | MSSV |
|-----------|------|
| Lê Chánh Ân | 23520007 |
| Phan Đình Khải | 23520678 |

---

## Giới thiệu

Dự án xây dựng hệ thống Machine Learning end-to-end để dự đoán giá nhà, dùng mô hình **XGBoost**. Toàn bộ quy trình từ xử lý dữ liệu, huấn luyện, đến triển khai đều được tự động hóa theo hướng MLOps — bao gồm CI/CD, Continuous Training và GitOps trên AWS.

Hệ thống gồm một **REST API** (FastAPI) phục vụ dự đoán thời gian thực/batch và một **Streamlit dashboard** để người dùng tương tác trực tiếp.

---

## 🛠 Tech Stack

- **Machine Learning:** XGBoost, Scikit-learn, Optuna, MLflow, Pandas, NumPy
- **Backend & UI:** FastAPI, Streamlit, Uvicorn
- **Infrastructure (AWS):** S3, ECR, EKS (Kubernetes), VPC Endpoints (PrivateLink)
- **DevOps & MLOps:** Terraform (IaC), Argo CD (GitOps), GitHub Actions, Docker, `uv`
- **Security & Quality:** SonarQube, Trivy

---

## 📐 Kiến trúc hệ thống

![MLOps Architecture](architectML.png)

Dữ liệu chạy qua các bước theo thứ tự:

```
Load → Preprocess → Feature Engineering → Train → Tune → Evaluate → Inference → Batch → Serve
```

### 1. Core Modules

**`src/feature_pipeline/`**
- `load.py` — Chia dữ liệu theo thời gian: train (< 2020), eval (2020–21), holdout (≥ 2022)
- `preprocess.py` — Chuẩn hóa tên thành phố, xóa trùng lặp, lọc ngoại lai
- `feature_engineering.py` — Tạo feature thời gian, frequency encoding (zipcode), target encoding (city_full)

**`src/training_pipeline/`**
- `train.py` — Huấn luyện XGBoost baseline
- `tune.py` — Tối ưu siêu tham số bằng Optuna, ghi log với MLflow
- `eval.py` — Đánh giá mô hình và tính các metrics

**`src/inference_pipeline/`**
- `inference.py` — Chạy dự đoán bằng cách dùng lại các encoder và transform đã lưu từ lúc train

**`src/batch/`**
- `run_monthly.py` — Chạy dự đoán batch định kỳ trên tập holdout

**`src/api/`**
- `main.py` — FastAPI với các endpoint dự đoán, xử lý batch và kết nối S3

### 2. Web App (`app.py`)

Streamlit dashboard gọi API để lấy kết quả dự đoán thời gian thực. Hỗ trợ lọc theo năm, tháng, khu vực và hiển thị biểu đồ so sánh dự đoán vs thực tế.

### 3. Hạ tầng Cloud & GitOps

Mã nguồn ứng dụng và cấu hình triển khai được tách thành 2 repository riêng biệt theo chuẩn GitOps:

👉 **GitOps Repository:** [Development-and-Deployment-of-a-Housing-Price-Prediction-System-using-MLOps-GitOps](https://github.com/khaipd18/Development-and-Deployment-of-a-Housing-Price-Prediction-System-using-MLOps-GitOps.git)

| Thành phần | Vai trò |
|------------|---------|
| **AWS S3** | Lưu dữ liệu thô, dữ liệu đã xử lý, model và encoder (`housing-regression-data-mlops`) |
| **Amazon ECR** | Lưu Docker images cho API và UI |
| **Amazon EKS** | Cụm Kubernetes chạy các container backend và frontend |
| **VPC Endpoints** | Cho phép EKS giao tiếp với S3, ECR, EC2, CloudWatch qua mạng nội bộ, không cần ra Internet |
| **Terraform** | Quản lý toàn bộ hạ tầng bằng code (VPC, EKS, ECR, VPC Endpoints, IAM OIDC) |
| **Argo CD** | Lắng nghe thay đổi từ GitOps repo và tự động sync trạng thái lên EKS |
| **GitHub Actions** | Chạy các pipeline CI/CD và Continuous Training |

---

## 📊 Kết quả mô hình

Mô hình XGBoost sau khi tune bằng Optuna, đánh giá trên tập Holdout (dữ liệu ≥ 2022):

| Metric | Value |
|--------|-------|
| **MAE** | 32,900.98 |
| **RMSE** | 74,151.63 |
| **R² Score** | 0.9575 |

Kết quả chi tiết từng lần chạy có thể xem tại giao diện MLflow (`http://localhost:5000`).

---

## Điểm nhấn thiết kế

**Time-based Splitting** — Thay vì split ngẫu nhiên, dữ liệu được chia theo thời gian: train (< 2020), eval (2020–21), holdout (≥ 2022). Cách này mô phỏng đúng thực tế — dùng dữ liệu quá khứ để dự đoán tương lai — nên kết quả đánh giá đáng tin hơn nhiều so với random split.

**Encoder Persistence** — Frequency encoder và target encoder chỉ được fit trên tập train, lưu thành file `.pkl` lên S3. Khi inference, hệ thống load lại đúng những file này. Cách này tránh data leakage và đảm bảo dữ liệu đầu vào lúc serving có cùng cấu trúc với lúc train.

**Continuous Training tự động** — Workflow CT chạy theo lịch (cron job ngày 1 hàng tháng), tự kéo dữ liệu mới từ S3, chạy lại toàn bộ pipeline và cập nhật model mới nhất — không cần ai làm thủ công.

**DevSecOps** — CI/CD tích hợp SonarQube để quét code tĩnh và Trivy để quét lỗ hổng CVE trong Docker image trước khi push lên ECR. Bảo mật được kiểm tra ngay trong pipeline, không phải sau khi deploy.

**VPC Endpoints** — Worker node của EKS nằm trong private subnet, kết nối S3 và ECR qua VPC Endpoints nên không cần NAT Gateway hay đi ra Internet. Vừa tiết kiệm chi phí vừa thu hẹp bề mặt tấn công.

**GitOps** — Toàn bộ trạng thái deploy được khai báo trong Git. Argo CD là thứ duy nhất được phép apply lên cluster, không có thao tác tay nào trực tiếp vào EKS.

---

## Chuẩn bị dữ liệu

Trước khi chạy bất kỳ pipeline nào, cần tải dataset thô về trước:

1. Vào Kaggle: [HouseTS Dataset](https://www.kaggle.com/datasets/shengkunwang/housets-dataset)
2. Tải file về máy
3. Đổi tên thành `untouched_raw_original.csv`
4. Đặt vào: `data/raw/untouched_raw_original.csv`

---

## Chạy trên Local

### Cài đặt môi trường

```bash
uv venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
uv pip install -r requirements.txt
```

### Chạy các pipeline

```bash
# 1. Xử lý dữ liệu
python src/feature_pipeline/load.py
python -m src.feature_pipeline.preprocess
python -m src.feature_pipeline.feature_engineering

# 2. Huấn luyện & đánh giá
python src/training_pipeline/train.py
python src/training_pipeline/tune.py
python src/training_pipeline/eval.py

# 3. Khởi động services
uv run uvicorn src.api.main:app --host 0.0.0.0 --port 8000       # API
streamlit run app.py --server.port 8501 --server.address 0.0.0.0  # UI
```

### MLflow UI

```bash
mlflow ui
```

Truy cập `http://localhost:5000` để xem lịch sử các lần chạy và biểu đồ tuning của Optuna.

---

## 🔌 API Documentation

Sau khi API chạy, vào `http://localhost:8000/docs` để xem Swagger UI.

Ví dụ gọi API dự đoán:

```bash
curl -X POST 'http://localhost:8000/predict' \
  -H 'Content-Type: application/json' \
  -d '{
    "zipcode": 98101,
    "bedrooms": 3,
    "bathrooms": 2.0,
    "sqft_living": 1500
  }'
```

---

## Tự động hóa trên Cloud

### Bước 1 — Triển khai hạ tầng (Terraform)

Có thể trigger tự động qua GitHub Actions (`infra.yml`), hoặc chạy thủ công:

```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

### Bước 2 — Upload dữ liệu lên S3

```bash
aws s3 cp data/raw/untouched_raw_original.csv s3://housing-regression-data-mlops/raw/untouched_raw_original.csv
```

### Bước 3 — Continuous Training (CT)

Workflow `ct.yaml` — chạy thủ công qua `workflow_dispatch` hoặc tự động vào ngày 1 hàng tháng.

Pipeline sẽ:
1. Pull dữ liệu từ S3
2. Chạy toàn bộ data pipeline
3. Train, tune (Optuna) và evaluate, ghi log bằng MLflow
4. Đẩy model, encoder, dữ liệu đã xử lý ngược lên S3

### Bước 4 — CI/CD

Workflow `ci.yml` — tự động chạy khi có push hoặc merge vào nhánh `main`.

Pipeline sẽ:
1. Kiểm tra code với SonarQube và chạy unit test (Pytest)
2. Build 2 Docker images: `housing-api` và `housing-ui`
3. Quét lỗ hổng bảo mật bằng Trivy
4. Push images lên Amazon ECR
5. Dùng `yq` để tự động cập nhật image tag (`github.sha`) vào `values-dev.yaml` trong GitOps repo

### Bước 5 — GitOps (Argo CD)

Sau khi CI/CD cập nhật tag mới vào GitOps repo, Argo CD phát hiện thay đổi và tự động deploy phiên bản mới lên EKS theo chiến lược Rolling Update — không gây downtime.

> Hướng dẫn cài đặt và cấu hình Argo CD trên EKS xem tại [GitOps Repository](https://github.com/khaipd18/Development-and-Deployment-of-a-Housing-Price-Prediction-System-using-MLOps-GitOps.git).

---

## 📁 Cấu trúc thư mục

```
├── .github/workflows/
│   ├── ci.yml                 # CI/CD: test, build, push ECR, cập nhật GitOps
│   ├── ct.yaml                # Continuous Training: chạy định kỳ hàng tháng
│   └── infra.yml              # Terraform: kiểm tra và apply hạ tầng
├── configs/                   # File cấu hình tham số hệ thống và mô hình
├── data/
│   ├── raw/                   # Dữ liệu thô (untouched_raw_original.csv)
│   ├── processed/             # Dữ liệu sau feature engineering
│   └── predictions/           # Kết quả dự đoán batch
├── models/                    # File model (.pkl) và encoder đã train
├── notebooks/                 # Jupyter Notebooks cho EDA và thử nghiệm
├── src/
│   ├── api/                   # FastAPI backend
│   ├── batch/                 # Script dự đoán batch hàng tháng
│   ├── feature_pipeline/      # Load, preprocess, feature engineering
│   ├── training_pipeline/     # Train, tune, evaluate
│   └── inference_pipeline/    # Inference cho production
├── terraform/
│   ├── modules/
│   │   ├── vpc-endpoints/     # Cấu hình AWS PrivateLink
│   │   ├── eks/               # Cụm EKS và worker nodes
│   │   ├── ecr/               # Docker image registry
│   │   └── github-oidc-role/  # IAM role cho GitHub Actions
│   ├── main.tf
│   └── backend.tf             # Remote state (S3)
├── tests/                     # Unit tests và dummy data
├── app.py                     # Streamlit UI
├── Dockerfile                 # Image cho FastAPI
├── Dockerfile.streamlit       # Image cho Streamlit
├── pyproject.toml / uv.lock
└── requirements.txt
```

---

## 🧹 Teardown — Dọn dẹp hệ thống

Khi muốn dọn dẹp hệ thống để tiết kiệm chi phí, **bạn bắt buộc phải xóa toàn bộ tài nguyên ứng dụng trên Kubernetes (đặc biệt là Ingress) trước khi chạy `terraform destroy` bên repo hạ tầng.**

**Tại sao phải làm vậy?**

> Các ALB trong dự án được tạo tự động bởi **AWS Load Balancer Controller** bên trong EKS, không phải do Terraform quản lý. Nếu chạy `terraform destroy` ngay, Terraform sẽ không xóa được VPC vì các ALB này vẫn đang giữ Network Interface (ENI) trong Subnet.
>
> **Lưu ý:** Không dùng `kubectl delete ingress` thủ công — Argo CD đang bật `selfHeal` và sẽ lập tức tạo lại ALB ngay khi bạn vừa xóa. Cách duy nhất là xóa toàn bộ Application.

**Quy trình dọn dẹp chuẩn (Cascade Delete):**

**1. Gỡ bỏ toàn bộ ứng dụng qua Argo CD (App of Apps):**

Nhờ `finalizers` đã được cấu hình, khi xóa App gốc, Argo CD tự động dọn sạch toàn bộ tài nguyên con — bao gồm cả Ingress và ALB:

```bash
kubectl delete -k argocd/root/
```

**2. Chờ AWS thu hồi Load Balancer:**

Vào AWS Console → EC2 → Load Balancers, đợi khoảng 2–3 phút cho đến khi các ALB của Dev và Prod biến mất hoàn toàn.

**3. Chạy terraform destroy:**

```bash
terraform destroy
```