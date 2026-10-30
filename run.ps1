$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

function Step($n, $msg) { Write-Host "`n[$n] $msg" -ForegroundColor Cyan }

$dockerDir = "$env:LOCALAPPDATA\Programs\DockerDesktop\resources\bin"
if (-not (Get-Command docker -ErrorAction SilentlyContinue) -and (Test-Path $dockerDir)) {
    $env:Path = "$dockerDir;$env:Path"
}

$jarPath = "jobs\lib\mysql-connector-j-8.0.33.jar"
if (-not (Test-Path $jarPath)) {
    Write-Host "JDBC 驱动不在，先下载……"
    New-Item -ItemType Directory -Force (Split-Path $jarPath) | Out-Null
    Invoke-WebRequest -UseBasicParsing -Uri "https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar" -OutFile $jarPath
}

Step 0 "等待 Docker 引擎就绪（最多 120 秒）"
$ready = $false
for ($i = 0; $i -lt 60; $i++) {
    docker info *> $null
    if ($LASTEXITCODE -eq 0) { $ready = $true; break }
    Start-Sleep -Seconds 2
}
if (-not $ready) {
    Write-Host "Docker 引擎没起来。先打开 Docker Desktop，等左下角显示 Engine running 再重跑本脚本。" -ForegroundColor Red
    exit 1
}
Write-Host "引擎已就绪：$(docker version --format '{{.Server.Version}}')"

Step 1 "拉取镜像（首次约 850 MB）"
docker compose pull

Step 2 "启动容器"
docker compose up -d

Step 3 "等待 MySQL 变成 healthy"
$ok = $false
for ($i = 0; $i -lt 60; $i++) {
    $status = docker inspect --format "{{.State.Health.Status}}" olist-mysql 2>$null
    if ($status -eq "healthy") { $ok = $true; break }
    Start-Sleep -Seconds 2
}
if (-not $ok) {
    Write-Host "MySQL 没能变成 healthy，看日志：" -ForegroundColor Red
    docker compose logs --tail 40 mysql
    exit 1
}
Write-Host "MySQL 已就绪"

Step 4 "确认源表数据"
docker compose exec mysql sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SELECT COUNT(*) AS rows_cnt FROM shop.orders;"'

Step 5 "提交 Spark 作业"
docker compose exec spark-master /opt/spark/bin/spark-submit `
    --master spark://spark-master:7077 `
    --jars /opt/jobs/lib/mysql-connector-j-8.0.33.jar `
    /opt/jobs/hello_spark.py

Step 6 "从 MySQL 回读结果"
docker compose exec mysql sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SELECT * FROM shop.category_summary ORDER BY total_amount DESC;"'

Write-Host "`n上面是 5 行、数字对得上，就说明跑通了。" -ForegroundColor Green
