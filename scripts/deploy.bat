@echo off
set ENV=%1

if "%ENV%"=="" (
  echo Usage: deploy.bat [dev|qa|prod]
  exit /b 1
)

echo Deploying Delphi POC to %ENV% environment...

if "%ENV%"=="dev" (
  copy ..\environments\dev.env ..\backend\.env /Y
) else if "%ENV%"=="qa" (
  copy ..\environments\qa.env ..\backend\.env /Y
) else if "%ENV%"=="prod" (
  copy ..\environments\prod.env ..\backend\.env /Y
)

cd ..\backend
call npm install
call npm start
