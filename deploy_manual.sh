#!/bin/bash
# Bash Script - Deploy from Private Cloud (Local) to Public Cloud (Azure) - MANUAL PASSWORD
# Purpose: Control Node is Local VMware. Prompts for password when connecting to Azure.
# Author: Glass

AZURE_USER="glass"
SKIP_BUILD=false

# Parse command line arguments (Đã bỏ Private IP/User)
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --azure-ip) AZURE_IP="$2"; shift ;;
        --azure-user) AZURE_USER="$2"; shift ;;
        --skip-build) SKIP_BUILD=true ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Check required parameters
if [ -z "$AZURE_IP" ]; then
    echo -e "\033[0;31m❌ Lỗi: Thiếu tham số bắt buộc. Vui lòng cung cấp --azure-ip\033[0m"
    echo "Sử dụng: ./deploy_manual_from_local.sh --azure-ip <IP> [--azure-user <USER>] [--skip-build]"
    exit 1
fi

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

write_success() { echo -e "${GREEN}✅ $1${NC}"; }
write_info() { echo -e "${CYAN}ℹ️ $1${NC}"; }
write_error() { echo -e "${RED}❌ $1${NC}"; }
write_warning() { echo -e "${YELLOW}⚠️ $1${NC}"; }

# Directories
ROOT_DIR=$(pwd)
FRONTEND_DIR="$ROOT_DIR/FrontEnd"
BACKEND_DIR="$ROOT_DIR/BackEnd"

write_info "==========================================="
write_info "☁️  Hybrid Cloud Deployment (Manual - Local Node)"
write_info "==========================================="
write_info "🔒 Cloud Private: Localhost (VMware)"
write_info "☁️  Cloud Public:  $AZURE_IP (User: $AZURE_USER)"
write_info "📁 Root Directory: $ROOT_DIR"
write_info "=========================================="
echo ""

# ========== STEP 0: CHECK & START CLOUD PRIVATE (RUNNING LOCALLY) ==========
write_info "🔒 STEP 0: Checking & Starting Database (Local)..."

DB_CONTAINER="mysql"
# Chạy thẳng lệnh docker locally
MYSQL_STATUS=$(docker ps -a --filter "name=^${DB_CONTAINER}$" --format "{{.State}}")
MYSQL_STATUS=$(echo "$MYSQL_STATUS" | xargs)

if [ "$MYSQL_STATUS" == "running" ]; then
    write_success "MySQL container is already running locally."
elif [ "$MYSQL_STATUS" == "exited" ] || [ "$MYSQL_STATUS" == "created" ]; then
    write_warning "MySQL container exists but is stopped. Starting it..."
    docker start $DB_CONTAINER 2>&1
    if [ $? -ne 0 ]; then
        write_error "Error starting MySQL container"
        exit 1
    fi
    write_success "MySQL container started successfully!"
    sleep 3
else
    write_warning "MySQL container does not exist. Preparing to create..."
    
    if [ ! -f "$ROOT_DIR/docker-compose-mysql.yml" ]; then
        write_error "Không tìm thấy file docker-compose-mysql.yml tại $ROOT_DIR"
        exit 1
    fi

    write_info "System will start MySQL container from compose file..."
    cd "$ROOT_DIR" || exit
    docker compose -f docker-compose-mysql.yml up -d 2>&1
    if [ $? -ne 0 ]; then
        write_error "Error creating/starting MySQL container"
        exit 1
    fi

    write_info "Waiting for MySQL to initialize (15s)..."
    sleep 15
    
    write_info "Auto-granting MySQL privileges..."
    docker exec mysql mysql -u root -p1 -e "CREATE USER IF NOT EXISTS 'root'@'%'; ALTER USER 'root'@'%' IDENTIFIED BY '1'; GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    if [ $? -eq 0 ]; then
        write_success "MySQL privileges granted!"
    else
        write_warning "Error granting MySQL privileges."
    fi
    sleep 2
fi

write_info "Checking MySQL connection..."
ss -tulpn | grep 3306 > /dev/null
if [ $? -eq 0 ]; then
    write_success "MySQL listening on port 3306"
else
    write_warning "Cannot verify port 3306, but MySQL container is running"
fi

echo ""
write_success "Cloud Private (VMware) - READY!"
echo ""

# ========== STEP 1: BUILD FRONTEND ==========
write_info "🔨 STEP 1: Building Frontend with Docker..."

if [ ! -d "$FRONTEND_DIR" ]; then
    write_error "Error: FrontEnd directory not found: $FRONTEND_DIR"
    exit 1
fi

if [ "$SKIP_BUILD" = true ]; then
    write_info "⏭️  Skipping Frontend build"
else
    cd "$FRONTEND_DIR" || exit
    write_info "Running Docker build command for Frontend..."
    docker run --rm -v "$(pwd):/app" -v /app/node_modules -w /app node:20-alpine sh -c "npm install && npm run build"
    
    if [ $? -ne 0 ]; then
        write_error "Error: Frontend build failed"
        exit 1
    fi
    if [ ! -d "build" ]; then
        write_error "Error: Build directory was not created"
        exit 1
    fi
    write_success "Frontend build completed!"
fi
echo ""

# ========== STEP 2: BUILD BACKEND ==========
write_info "🔨 STEP 2: Building Backend with Docker..."

if [ ! -d "$BACKEND_DIR" ]; then
    write_error "Error: BackEnd directory not found: $BACKEND_DIR"
    exit 1
fi

if [ "$SKIP_BUILD" = true ]; then
    write_info "⏭️  Skipping Backend build"
else
    cd "$BACKEND_DIR" || exit
    write_info "Running Docker build command for Backend..."
    docker run --rm -v "$(pwd):/app" -w /app maven:3.9.9-eclipse-temurin-17 mvn clean package -DskipTests
    
    if [ $? -ne 0 ]; then
        write_error "Error: Backend build failed"
        exit 1
    fi

    count=$(ls -1 target/*.jar 2>/dev/null | wc -l)
    if [ "$count" -eq 0 ]; then
        write_error "Error: JAR file was not created in target/ directory"
        exit 1
    fi
    write_success "Backend build completed!"
fi
echo ""

# ========== STEP 3: UPLOAD TO AZURE ==========
write_info "🚀 STEP 3: Uploading to Azure via tar.gz archive..."
cd "$ROOT_DIR" || exit

write_info "📦 Compressing files into BTL.tar.gz..."
tar -czvf BTL.tar.gz FrontEnd/build FrontEnd/nginx.conf FrontEnd/Dockerfile BackEnd/target/*.jar BackEnd/Dockerfile docker-compose.yml > /dev/null 2>&1
if [ $? -ne 0 ]; then
    write_error "Error compressing files"
    exit 1
fi

write_info "📤 Uploading BTL.tar.gz to Azure (MỜI BẠN NHẬP MẬT KHẨU AZURE)..."
scp -o StrictHostKeyChecking=no BTL.tar.gz "$AZURE_USER@$AZURE_IP:~/"
if [ $? -ne 0 ]; then
    write_error "Error uploading BTL.tar.gz"
    exit 1
fi

write_info "📂 Extracting files on Azure (MỜI BẠN NHẬP MẬT KHẨU LẦN 2)..."
ssh -o StrictHostKeyChecking=no "$AZURE_USER@$AZURE_IP" "mkdir -p ~/BTL && tar -xzvf ~/BTL.tar.gz -C ~/BTL && rm ~/BTL.tar.gz"
if [ $? -ne 0 ]; then
    write_error "Error extracting files on Azure"
    exit 1
fi

write_info "🧹 Cleaning up local archive..."
rm -f BTL.tar.gz

write_success "Files uploaded and extracted successfully!"
echo ""

# ========== STEP 4: START DOCKER COMPOSE ==========
write_info "🐳 STEP 4: Starting Docker Compose on Azure..."

write_info "(MỜI BẠN NHẬP MẬT KHẨU LẦN 3 ĐỂ KHỞI ĐỘNG DOCKER)..."
ssh -o StrictHostKeyChecking=no "$AZURE_USER@$AZURE_IP" "cd ~/BTL && docker compose up -d --build"
if [ $? -ne 0 ]; then
    write_error "Error: Failed to start Docker Compose"
    exit 1
fi
write_success "Docker Compose started!"
echo ""

# ========== STEP 5: DISPLAY CONNECTION INFO ==========
write_info "========================================"
write_success "DEPLOYMENT COMPLETED SUCCESSFULLY!"
write_info "========================================"
echo ""
write_info "🔒 Cloud Private (Local VMware - Database):"
write_info "   - Location: Localhost"
write_info "   - MySQL Port: 3306"
echo ""
write_info "☁️  Cloud Public (Azure - Web):"
write_info "   - Website:      http://$AZURE_IP"
write_info "   - Backend API:  http://$AZURE_IP/api"
echo ""
write_warning "💡 Please wait 30 seconds for all containers to fully start!"