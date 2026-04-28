#!/bin/bash
# Bash Script - Deploy Hybrid Cloud System (Auto Password)
# Author: Glass

# Check if sshpass is installed
if ! command -v sshpass &> /dev/null; then
    echo -e "\033[0;31m✗ Lỗi: 'sshpass' chưa được cài đặt. Hãy chạy 'sudo apt install sshpass' trước!\033[0m"
    exit 1
fi

AZURE_USER="glass"
PRIVATE_USER="glass"
SKIP_BUILD=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --azure-ip) AZURE_IP="$2"; shift ;;
        --private-ip) PRIVATE_IP="$2"; shift ;;
        --azure-user) AZURE_USER="$2"; shift ;;
        --private-user) PRIVATE_USER="$2"; shift ;;
        --azure-pass) AZURE_PASS="$2"; shift ;;
        --private-pass) PRIVATE_PASS="$2"; shift ;;
        --skip-build) SKIP_BUILD=true ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$AZURE_IP" ] || [ -z "$PRIVATE_IP" ] || [ -z "$AZURE_PASS" ] || [ -z "$PRIVATE_PASS" ]; then
    echo -e "\033[0;31m✗ Lỗi: Thiếu tham số bắt buộc.\033[0m"
    echo "Sử dụng: ./deploy_auto.sh --azure-ip <IP> --azure-pass <PASS> --private-ip <IP> --private-pass <PASS>"
    exit 1
fi

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

write_success() { echo -e "${GREEN}✅ $1${NC}"; }
write_info() { echo -e "${CYAN}ℹ️ $1${NC}"; }
write_error() { echo -e "${RED}❌ $1${NC}"; }
write_warning() { echo -e "${YELLOW}⚠️ $1${NC}"; }

ROOT_DIR=$(pwd)
FRONTEND_DIR="$ROOT_DIR/FrontEnd"
BACKEND_DIR="$ROOT_DIR/BackEnd"

write_info "☁️  Hybrid Cloud Deployment Script (Auto with SSHPASS)"

# ========== STEP 0: CLOUD PRIVATE ==========
write_info "🔒 STEP 0: Checking Database (Cloud Private)..."
DB_CONTAINER="mysql"

MYSQL_STATUS=$(sshpass -p "$PRIVATE_PASS" ssh -o StrictHostKeyChecking=no "$PRIVATE_USER@$PRIVATE_IP" "docker ps -a --filter 'name=^${DB_CONTAINER}$' --format '{{.State}}'")
MYSQL_STATUS=$(echo "$MYSQL_STATUS" | xargs)

if [ "$MYSQL_STATUS" == "running" ]; then
    write_success "MySQL container is already running."
elif [ "$MYSQL_STATUS" == "exited" ] || [ "$MYSQL_STATUS" == "created" ]; then
    write_warning "MySQL is stopped. Starting it..."
    sshpass -p "$PRIVATE_PASS" ssh -o StrictHostKeyChecking=no "$PRIVATE_USER@$PRIVATE_IP" "docker start $DB_CONTAINER 2>&1"
    sleep 3
else
    write_warning "MySQL container missing. Creating..."
    sshpass -p "$PRIVATE_PASS" ssh -o StrictHostKeyChecking=no "$PRIVATE_USER@$PRIVATE_IP" "test -f ~/docker-compose-mysql.yml"
    
    if [ $? -ne 0 ]; then
        cd "$ROOT_DIR" || exit
        sshpass -p "$PRIVATE_PASS" scp -o StrictHostKeyChecking=no docker-compose-mysql.yml "$PRIVATE_USER@$PRIVATE_IP:~/"
    fi

    sshpass -p "$PRIVATE_PASS" ssh -o StrictHostKeyChecking=no "$PRIVATE_USER@$PRIVATE_IP" "cd ~/ && docker compose -f docker-compose-mysql.yml up -d 2>&1"
    
    sshpass -p "$PRIVATE_PASS" ssh -o StrictHostKeyChecking=no "$PRIVATE_USER@$PRIVATE_IP" "docker exec mysql mysql -u root -p1 -e \"GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;\""
    sleep 5
fi

write_success "Cloud Private (VMware) - READY!"

# ========== STEP 1 & 2: BUILD ==========
if [ "$SKIP_BUILD" = true ]; then
    write_info "⏭️  Skipping Builds"
else
    write_info "🔨 Building Frontend..."
    cd "$FRONTEND_DIR" || exit
    docker run --rm -v "$(pwd):/app" -v /app/node_modules -w /app node:20-alpine sh -c "npm install && npm run build"
    
    write_info "🔨 Building Backend..."
    cd "$BACKEND_DIR" || exit
    docker run --rm -v "$(pwd):/app" -w /app maven:3.9.9-eclipse-temurin-17 mvn clean package -DskipTests
fi

# ========== STEP 3: UPLOAD TO AZURE ==========
write_info "🚀 STEP 3: Uploading to Azure via tar.gz archive..."
cd "$ROOT_DIR" || exit

write_info "📦 Compressing files into BTL.tar.gz..."
tar -czvf BTL.tar.gz FrontEnd/build FrontEnd/nginx.conf FrontEnd/Dockerfile BackEnd/target/*.jar BackEnd/Dockerfile docker-compose.yml > /dev/null 2>&1
if [ $? -ne 0 ]; then
    write_error "Error compressing files"
    exit 1
fi

write_info "📤 Uploading BTL.tar.gz to Azure..."
sshpass -p "$AZURE_PASS" scp -o StrictHostKeyChecking=no BTL.tar.gz "$AZURE_USER@$AZURE_IP:~/"
if [ $? -ne 0 ]; then
    write_error "Error uploading BTL.tar.gz"
    exit 1
fi

write_info "📂 Extracting files on Azure..."
sshpass -p "$AZURE_PASS" ssh -o StrictHostKeyChecking=no "$AZURE_USER@$AZURE_IP" "mkdir -p ~/BTL && tar -xzvf ~/BTL.tar.gz -C ~/BTL && rm ~/BTL.tar.gz"
if [ $? -ne 0 ]; then
    write_error "Error extracting files on Azure"
    exit 1
fi

write_info "🧹 Cleaning up local archive..."
rm -f BTL.tar.gz

write_success "Files uploaded and extracted successfully!"
echo ""

# ========== STEP 4: START AZURE ==========
write_info "🐳 STEP 4: Starting Docker Compose..."
sshpass -p "$AZURE_PASS" ssh -o StrictHostKeyChecking=no "$AZURE_USER@$AZURE_IP" "cd ~/BTL && docker compose up -d"

write_success "DEPLOYMENT COMPLETED SUCCESSFULLY!"

# ========== STEP 5: DISPLAY CONNECTION INFO ==========
write_info "========================================"
write_success "DEPLOYMENT COMPLETED SUCCESSFULLY!"
write_info "========================================"
echo ""
write_info "🔒 Cloud Private (VMware - Database):"
write_info "   - IP: $PRIVATE_IP"
write_info "   - MySQL: 10.8.0.2:3306"
echo ""
write_info "☁️  Cloud Public (Azure - Web):"
write_info "   - Website:      http://$AZURE_IP"
write_info "   - Backend API:  http://$AZURE_IP/api"
echo ""
write_warning "💡 Please wait 30 seconds for all containers to fully start!"