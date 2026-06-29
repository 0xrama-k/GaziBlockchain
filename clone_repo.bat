@echo off

set REPO_URL=https://github.com/0xrama-k/GaziBlockchain.git
set TARGET_DIR=C:\rama\team\Gazi Blockchain Team

if not exist "%TARGET_DIR%" (
    git clone "%REPO_URL%" "%TARGET_DIR%"
) else (
    cd /d "%TARGET_DIR%"
    git pull
)

pause