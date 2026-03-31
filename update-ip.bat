@echo off
REM ============================================
REM  update-ip.bat - Tu dong cap nhat IP + Ngrok URL
REM  Chay file nay moi khi doi mang (truong / nha / wifi khac)
REM ============================================

REM Lay IPv4 dau tien (bo qua loopback 127.0.0.1)
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do (
    set "IP=%%a"
    goto :found
)
echo [ERROR] Khong tim thay dia chi IPv4!
pause
exit /b 1

:found
REM Xoa khoang trang dau
set "IP=%IP: =%"

echo.
echo  +==================================================+
echo  ^|   IP hien tai cua ban: %IP%
echo  +==================================================+
echo.

REM ============================================
REM  Cap nhat mobile_app/.env (IP cho Flutter)
REM ============================================
set "ENV_FILE=%~dp0mobile_app\.env"

(
echo # CHI DOI 1 CHO KHI BAN CHUYEN MAY / CHUYEN MANG:
echo # - Android Emulator: co the de http://10.0.2.2:3000/api
echo # - iOS Simulator: co the de http://localhost:3000/api
echo # - Thiet bi that ^(Android/iPhone qua WiFi^): dung IP LAN cua may chay backend
echo # =============================================================
echo # CACH NHANH: Chay file update-ip.bat o thu muc goc du an
echo # =============================================================
echo API_BASE_URL=http://%IP%:3000/api
) > "%ENV_FILE%"

echo [OK] Da cap nhat mobile_app\.env:
echo      API_BASE_URL=http://%IP%:3000/api
echo.

REM ============================================
REM  Tu dong lay Ngrok URL (neu ngrok dang chay)
REM ============================================
set "BACKEND_ENV=%~dp0backend_server\.env"
set "NGROK_URL="

REM Thu lay ngrok URL tu API local
curl -s http://127.0.0.1:4040/api/tunnels > "%TEMP%\ngrok_tunnels.json" 2>nul
if %ERRORLEVEL% EQU 0 (
    REM Parse ngrok URL tu JSON (lay public_url https)
    for /f "tokens=*" %%i in ('powershell -Command "try { $r = Get-Content '%TEMP%\ngrok_tunnels.json' | ConvertFrom-Json; $t = $r.tunnels | Where-Object { $_.proto -eq 'https' } | Select-Object -First 1; if ($t) { $t.public_url } else { $r.tunnels[0].public_url } } catch { '' }"') do (
        set "NGROK_URL=%%i"
    )
)

if defined NGROK_URL (
    echo [OK] Phat hien Ngrok URL: %NGROK_URL%
    
    REM Cap nhat NGROK_URL trong backend_server/.env
    powershell -Command "(Get-Content '%BACKEND_ENV%') -replace '^NGROK_URL=.*', 'NGROK_URL=%NGROK_URL%' | Set-Content '%BACKEND_ENV%'"
    
    echo [OK] Da cap nhat backend_server\.env:
    echo      NGROK_URL=%NGROK_URL%

    REM Upload ngrok URL len Gist
    REM Vui long tao file .env hoac dat bien moi truong cho GIST_ID va GITHUB_TOKEN xuyen suot
    powershell -Command "$body = @{files=@{'ngrok-url.txt'=@{content='%NGROK_URL%'}}} | ConvertTo-Json -Depth 5; Invoke-RestMethod -Uri 'https://api.github.com/gists/YOUR_GIST_ID' -Method Patch -Headers @{Authorization='token YOUR_GITHUB_TOKEN'} -ContentType 'application/json' -Body $body"
    echo [OK] Da upload ngrok URL len Gist
) else (
    echo [WARN] Khong phat hien Ngrok dang chay.
    echo        Neu can VNPay callback, hay chay: ngrok http 3000
    echo        Roi chay lai update-ip.bat
)

echo.
echo Gio ban co the chay lai app Flutter (hot restart / rebuild).
echo.
pause
