@echo off
setlocal
title PoliMusic - IIS Express

set "APPDIR=%~dp0"
if "%APPDIR:~-1%"=="\" set "APPDIR=%APPDIR:~0,-1%"

set "IISEXPRESS=%ProgramFiles%\IIS Express\iisexpress.exe"
if exist "%IISEXPRESS%" goto :encontrado
set "IISEXPRESS=%ProgramFiles(x86)%\IIS Express\iisexpress.exe"
if exist "%IISEXPRESS%" goto :encontrado

echo.
echo No se encontro IIS Express.
echo Instala IIS Express 10 o Visual Studio con la carga de trabajo ASP.NET.
echo.
pause
exit /b 1

:encontrado
if not exist "%APPDIR%\.iisexpress\applicationHost.config" goto :errorcfg

set "CFG=%TEMP%\polimusic-iisexpress.config"
echo Generando configuracion para: %APPDIR%
powershell -NoProfile -ExecutionPolicy Bypass -Command "$app=$env:APPDIR; $src=Join-Path $app '.iisexpress\applicationHost.config'; $tpl=[IO.File]::ReadAllText($src); $dst=Join-Path $env:TEMP 'polimusic-iisexpress.config'; [IO.File]::WriteAllText($dst, $tpl.Replace('__APPDIR__',$app), (New-Object System.Text.UTF8Encoding($false)))"
if errorlevel 1 goto :errorcfg

echo.
echo PoliMusic disponible en: http://localhost:8099/
echo Cierra esta ventana para detener el servidor.
echo.
"%IISEXPRESS%" /config:"%CFG%" /site:PoliMusic /systray:false
goto :fin

:errorcfg
echo.
echo No se pudo preparar la configuracion de IIS Express.
echo Verifica que exista .iisexpress\applicationHost.config y que PowerShell este disponible.
echo.
pause
exit /b 1

:fin
endlocal
