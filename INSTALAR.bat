@echo off
REM Script para instalar os arquivos modificados no projeto Flutter
REM Caminho do projeto
set PROJETO_PATH=C:\Users\rhest\Documents\Faculdade\ProjetoDart\defesaemfoco

echo.
echo ================================================================================
echo INSTALANDO ARQUIVOS MODIFICADOS - DEFESA CIVIL APP
echo ================================================================================
echo.
echo Caminho do projeto: %PROJETO_PATH%
echo.

REM Verificar se o caminho existe
if not exist "%PROJETO_PATH%" (
    echo ERRO: Caminho do projeto nao encontrado!
    echo %PROJETO_PATH%
    pause
    exit /b 1
)

echo [1/4] Copiando pubspec.yaml...
copy /Y "pubspec.yaml" "%PROJETO_PATH%\pubspec.yaml" >nul
if %errorlevel% equ 0 (
    echo [OK] pubspec.yaml copiado com sucesso
) else (
    echo [ERRO] Falha ao copiar pubspec.yaml
    pause
    exit /b 1
)

echo.
echo [2/4] Copiando mapa_screen.dart...
if not exist "%PROJETO_PATH%\lib\screens" mkdir "%PROJETO_PATH%\lib\screens"
copy /Y "lib\screens\mapa_screen.dart" "%PROJETO_PATH%\lib\screens\mapa_screen.dart" >nul
if %errorlevel% equ 0 (
    echo [OK] mapa_screen.dart copiado com sucesso
) else (
    echo [ERRO] Falha ao copiar mapa_screen.dart
    pause
    exit /b 1
)

echo.
echo [3/4] Copiando README.md...
copy /Y "README.md" "%PROJETO_PATH%\README.md" >nul
if %errorlevel% equ 0 (
    echo [OK] README.md copiado com sucesso
) else (
    echo [ERRO] Falha ao copiar README.md
    pause
    exit /b 1
)

echo.
echo [4/4] Copiando AndroidManifest.xml...
if not exist "%PROJETO_PATH%\android\app\src\main" mkdir "%PROJETO_PATH%\android\app\src\main"
copy /Y "android\app\src\main\AndroidManifest.xml" "%PROJETO_PATH%\android\app\src\main\AndroidManifest.xml" >nul
if %errorlevel% equ 0 (
    echo [OK] AndroidManifest.xml copiado com sucesso
) else (
    echo [ERRO] Falha ao copiar AndroidManifest.xml
    pause
    exit /b 1
)

echo.
echo ================================================================================
echo PROXIMOS PASSOS
echo ================================================================================
echo.
echo 1. Abra o terminal/prompt de comando
echo.
echo 2. Navegue ate o projeto:
echo    cd "%PROJETO_PATH%"
echo.
echo 3. Atualize as dependencias:
echo    flutter pub get
echo.
echo 4. Execute o projeto:
echo    flutter run
echo.
echo ================================================================================
echo INSTALACAO CONCLUIDA COM SUCESSO!
echo ================================================================================
echo.
pause
