# Instructions for using automatic files

## On Windows:
Dùng PowerShell để chạy các script `.ps1`. Phải tự nhập mật khẩu khi được yêu cầu, đảm bảo rằng người dùng trên Azure VM đã được thiết lập và có quyền truy cập SSH.

```powershell
# Basic deployment
.\deploy.ps1 -AzureIP 20.235.122.97 -PrivateCloudIP 192.168.198.129

# With custom usernames
.\deploy.ps1 -AzureIP 20.235.122.97 -PrivateCloudIP 192.168.198.129 -AzureUsername myuser -PrivateUsername vmuser

# Skip build (only upload existing build/ and *.jar)
.\deploy.ps1 -AzureIP 20.235.122.97 -PrivateCloudIP 192.168.198.129 -SkipBuild
```

## On Linux/Mac:

**File 1: deploy_manual.sh**
Phải tự nhập mật khẩu khi được yêu cầu, đảm bảo rằng người dùng trên Azure VM đã được thiết lập và có quyền truy cập SSH.

```bash
chmod +x deploy_manual.sh

# Basic deployment
./deploy_manual.sh --azure-ip 20.235.122.97

# With custom usernames
./deploy_manual.sh --azure-ip 20.235.122.97 --azure-username myuser

# Skip build (only upload existing build/ and *.jar)
./deploy_manual.sh --azure-ip 20.235.122.97 --skip-build
```

**File 2: deploy_auto.sh**
Phải cài sshpass để chạy script này, có thể cài bằng lệnh `sudo apt install sshpass` trên Ubuntu hoặc `brew install sshpass` trên Mac. Thiết lập sshpass để sử dụng mật khẩu thay vì key-based authentication, đảm bảo rằng mật khẩu của người dùng trên Azure VM đã được thiết lập và có quyền truy cập SSH.

```bash
chmod +x deploy_auto.sh

# Basic deployment
./deploy_auto.sh --azure-ip 20.235.122.97 --azure-pass "MatKhauAzureCuaBan"

# With custom usernames
./deploy_auto.sh --azure-ip 20.235.122.97 --azure-pass "MatKhauAzureCuaBan" --azure-username myuser

# Skip build (only upload existing build/ and *.jar)
./deploy_auto.sh --azure-ip 20.235.122.97 --azure-pass "MatKhauAzureCuaBan" --skip-build
```