# PowerShell Script - Deploy Hybrid Cloud Hybrid Cloud System
# Purpose: Manage Cloud Private (VMware) + Build & Deploy to Cloud Public (Azure)
# Author: Glass

param(
    [Parameter(Mandatory=$true)]
    [string]$AzureIP,

    [Parameter(Mandatory=$true)]
    [string]$PrivateCloudIP,

    [Parameter(Mandatory=$false)]
    [string]$AzureUsername = "glass",

    [Parameter(Mandatory=$false)]
    [string]$PrivateUsername = "glass",

    [Parameter(Mandatory=$false)]
    [switch]$SkipBuild = $false
)

# Color output functions
function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️ $Message" -ForegroundColor Cyan
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠️ $Message" -ForegroundColor Yellow
}

# Get current directory
$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Info "Current directory: $RootDir"
$FrontendDir = Join-Path $RootDir "FrontEnd"
Write-Info "Frontend directory: $FrontendDir"
$BackendDir = Join-Path $RootDir "BackEnd"
Write-Info "Backend directory: $BackendDir"

Write-Info "==========================================="
Write-Info "☁️  Hybrid Cloud Deployment Script"
Write-Info "==========================================="
Write-Info "🔒 Cloud Private (VMware): $PrivateCloudIP"
Write-Info "   Username: $PrivateUsername"
Write-Info "☁️  Cloud Public (Azure):   $AzureIP"
Write-Info "   Username: $AzureUsername"
Write-Info "📁 Root Directory: $RootDir"
Write-Info "==========================================" 
Write-Info ""


# ========== STEP 0: CHECK & START CLOUD PRIVATE (VMware) ==========
Write-Info "🔒 STEP 0: Checking & Starting Database (Cloud Private)..."
Write-Info "Connecting to Cloud Private at $PrivateCloudIP..."

# Get the container's state directly (running / exited / or empty if not created).
$DbContainerName = "mysql"
$MysqlStatus = ssh -o StrictHostKeyChecking=no "$PrivateUsername@$PrivateCloudIP" "docker ps -a --filter `"name=^${DbContainerName}$`" --format `"{{.State}}`""

if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Error connecting to Cloud Private ($PrivateCloudIP)"
    Write-Error-Custom "   - Check if VMware machine has OpenVPN running"
    Write-Error-Custom "   - Verify username/password are correct"
    exit 1
}

$MysqlStatus = "$MysqlStatus".Trim()

# ----------------- DECISION TREE -----------------

# CASE 1: Container running -> Skip, move on to next step
if ($MysqlStatus -eq "running") {
    Write-Success "MySQL container is already running."
}
# CASE 2: Container is already there but is shut down -> Just restart it.
elseif ($MysqlStatus -eq "exited" -or $MysqlStatus -eq "created") {
    Write-Warning-Custom "MySQL container exists but is stopped. Starting it..."
    
    $StartResult = ssh -o StrictHostKeyChecking=no "$PrivateUsername@$PrivateCloudIP" "docker start $DbContainerName 2>&1"

    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Error starting MySQL container"
        Write-Error-Custom "   $StartResult"
        exit 1
    }
    
    Write-Success "MySQL container started successfully!"
    Start-Sleep -Seconds 3
}
# CASE 3: Container does not exist -> Must find file and create new
else {
    Write-Warning-Custom "MySQL container does not exist. Preparing to create..."

    # Step 3.1: Check if docker-compose file exists
    Write-Info "Checking for docker-compose-mysql.yml on Cloud Private..."
    $FileCheck = ssh -o StrictHostKeyChecking=no "$PrivateUsername@$PrivateCloudIP" "test -f ~/docker-compose-mysql.yml"

    if ($LASTEXITCODE -ne 0) {
        # If you haven't already -> Proceed to upload
        Write-Warning-Custom "docker-compose-mysql.yml not found, uploading..."

        Push-Location $RootDir
        scp -o StrictHostKeyChecking=no docker-compose-mysql.yml "$($PrivateUsername)@$($PrivateCloudIP):~/"
        $ScpExitCode = $LASTEXITCODE
        Pop-Location

        if ($ScpExitCode -ne 0) {
            Write-Error-Custom "Error uploading docker-compose-mysql.yml to Cloud Private"
            exit 1
        }
        Write-Success "docker-compose-mysql.yml uploaded successfully"
    } else {
        # If the file already exists -> No need to do anything else
        Write-Info "docker-compose-mysql.yml already exists"
    }

    # Step 3.2: Run command to create Container from compose file
    Write-Info "System will start MySQL container from docker-compose-mysql.yml..."
    $MysqlStart = ssh -o StrictHostKeyChecking=no "$PrivateUsername@$PrivateCloudIP" "cd ~/ && docker compose -f docker-compose-mysql.yml up -d 2>&1"

    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Error creating/starting MySQL container"
        Write-Error-Custom "   $MysqlStart"
        exit 1
    }

    # Step 3.3: Auto-grant MySQL privileges to VPN subnet (if not already granted)
    Write-Info "Auto-granting MySQL privileges to VPN subnet..."
    $GrantSql = ssh -o StrictHostKeyChecking=no -l "$PrivateUsername" "$PrivateCloudIP" "docker exec mysql mysql -u root -p1 -e `"GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;`""

    if ($LASTEXITCODE -eq 0) {
        Write-Success "MySQL privileges granted!"
    } else {
        Write-Warning-Custom "Error granting MySQL privileges (DB might be starting or privileges already granted)"
        Write-Info "   - Check if MySQL is running correctly and accepting connections"
    }

    Write-Success "MySQL container created and started!"
    Start-Sleep -Seconds 5
}

# Check if MySQL is listening on port 3306
Write-Info "Checking MySQL connection..."
$PortCheck = ssh -o StrictHostKeyChecking=no "$PrivateUsername@$PrivateCloudIP" "ss -tulpn | grep 3306"

if ($LASTEXITCODE -eq 0) {
    Write-Success "MySQL listening on port 3306"
} else {
    Write-Warning-Custom "Cannot verify port 3306, but MySQL container is running"
}

Write-Info ""
Write-Success "Cloud Private (VMware) - READY!"
Write-Info ""

# ========== STEP 1: BUILD FRONTEND ==========
Write-Info "🔨 STEP 1: Building Frontend with Docker..."

if (-not (Test-Path $FrontendDir)) {
    Write-Error-Custom "Error: FrontEnd directory not found: $FrontendDir"
    exit 1
}

if ($SkipBuild) {
    Write-Info "⏭️  Skipping Frontend build"
} else {
    Push-Location $FrontendDir
    
    $FrontendBuildCmd = @(
        "docker", "run", "--rm",
        "-v", "$($PWD):/app",
        "-v", "/app/node_modules",
        "-w", "/app",
        "node:20-alpine",
        "sh", "-c",
        "npm install && npm run build"
    )
    
    Write-Info "Running Docker build command for Frontend..."
    & $FrontendBuildCmd[0] $FrontendBuildCmd[1..($FrontendBuildCmd.Count-1)]
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Error: Frontend build failed"
        Pop-Location
        exit 1
    }
    
    if (-not (Test-Path "build")) {
        Write-Error-Custom "Error: Build directory was not created"
        Pop-Location
        exit 1
    }
    
    Write-Success "Frontend build completed!"
    Pop-Location
}

Write-Info ""

# ========== STEP 2: BUILD BACKEND ==========
Write-Info "🔨 STEP 2: Building Backend with Docker..."

if (-not (Test-Path $BackendDir)) {
    Write-Error-Custom "Error: BackEnd directory not found: $BackendDir"
    exit 1
}

if ($SkipBuild) {
    Write-Info "⏭️  Skipping Backend build"
} else {
    Push-Location $BackendDir
    
    $BackendBuildCmd = @(
        "docker", "run", "--rm",
        "-v", "$($PWD):/app",
        "-w", "/app",
        "maven:3.9.9-eclipse-temurin-17",
        "mvn", "clean", "package", "-DskipTests"
    )
    
    Write-Info "Running Docker build command for Backend..."
    & $BackendBuildCmd[0] $BackendBuildCmd[1..($BackendBuildCmd.Count-1)]
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Error: Backend build failed"
        Pop-Location
        exit 1
    }
    
    if (-not (Test-Path "target/*.jar")) {
        Write-Error-Custom "Error: JAR file was not created in target/ directory"
        Pop-Location
        exit 1
    }
    
    Write-Success "Backend build completed!"
    Pop-Location
}

Write-Info ""

# ========== STEP 3: UPLOAD TO AZURE ==========
Write-Info "🚀 STEP 3: Uploading to Azure via tar.gz archive..."

Push-Location $RootDir

# 1. Compress all necessary files into a single file.
Write-Info "📦 Compressing files into BTL.tar.gz..."
$TarCmd = "tar -czvf BTL.tar.gz FrontEnd/build FrontEnd/nginx.conf FrontEnd/Dockerfile BackEnd/target/*.jar BackEnd/Dockerfile docker-compose.yml"
Invoke-Expression $TarCmd

if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Error compressing files"
    Pop-Location
    exit 1
}

# 2. Upload the compressed file to Azure
Write-Info "📤 Uploading BTL.tar.gz to Azure..."
scp -o StrictHostKeyChecking=no BTL.tar.gz "$($AzureUsername)@$($AzureIP):~/"
$ScpExit = $LASTEXITCODE

if ($ScpExit -ne 0) {
    Write-Error-Custom "Error uploading BTL.tar.gz"
    Pop-Location
    exit 1
}

# 3. Create directory, extract, and clean up on Azure
Write-Info "📂 Extracting files on Azure..."
$ExtractCmd = "ssh -o StrictHostKeyChecking=no $($AzureUsername)@$($AzureIP) 'mkdir -p ~/BTL && tar -xzvf ~/BTL.tar.gz -C ~/BTL && rm ~/BTL.tar.gz'"
Invoke-Expression $ExtractCmd

if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Error extracting files on Azure"
    Pop-Location
    exit 1
}

# 4. Clean up local archive
Write-Info "🧹 Cleaning up local archive..."
Remove-Item -Path .\BTL.tar.gz -Force
Pop-Location

Write-Success "Files uploaded and extracted successfully!"
Write-Info ""

# ========== STEP 4: START DOCKER COMPOSE ==========
Write-Info "🐳 STEP 4: Starting Docker Compose on Azure..."

$SshCmd = "ssh -o StrictHostKeyChecking=no $($AzureUsername)@$($AzureIP) 'cd ~/BTL && docker compose up -d'"

Write-Info "Command: $SshCmd"
Invoke-Expression $SshCmd

if ($LASTEXITCODE -ne 0) {
    Write-Error-Custom "Error: Failed to start Docker Compose"
    exit 1
}

Write-Success "Docker Compose started!"
Write-Info ""

# ========== STEP 5: DISPLAY CONNECTION INFO ==========
Write-Info "========================================"
Write-Success "DEPLOYMENT COMPLETED SUCCESSFULLY!"
Write-Info "========================================"
Write-Info ""
Write-Info "🔒 Cloud Private (VMware - Database):"
Write-Info "   - IP: $PrivateCloudIP"
Write-Info "   - MySQL: 10.8.0.2:3306"
Write-Info "   - Check: ssh $PrivateUsername@$PrivateCloudIP 'docker ps'"
Write-Info ""
Write-Info "☁️  Cloud Public (Azure - Web):"
Write-Info "   - Website:      http://$AzureIP"
Write-Info "   - Backend API:  http://$AzureIP/api"
Write-Info "   - Swagger:      http://$AzureIP/swagger-ui.html"
Write-Info ""
Write-Info "📊 Check Azure status:"
Write-Info "   ssh $AzureUsername@$AzureIP"
Write-Info "   docker compose ps"
Write-Info ""
Write-Info "📋 View Backend logs:"
Write-Info "   ssh $AzureUsername@$AzureIP"
Write-Info "   docker compose logs -f backend"
Write-Info ""
Write-Info "⏹️  Stop all Azure containers:"
Write-Info "   ssh $AzureUsername@$AzureIP"
Write-Info "   docker compose down"
Write-Info ""
Write-Warning-Custom "💡 Please wait 30 seconds for all containers to fully start!"
