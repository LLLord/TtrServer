@start "unilight.exe" "unilight.exe" -d -c config.xml

@echo off
pushd "%~dp0"

echo 删除panic.* 的空文件
for /f "delims=" %%a in ('dir /a-d/b/s panic.*') do (
    if "%%~za"=="0" del "%%a"
)
echo 删除完毕

if exist config.xml (
	unilight.exe
) else (
	unilight.exe -c="config_default.xml"
)

pause
popd