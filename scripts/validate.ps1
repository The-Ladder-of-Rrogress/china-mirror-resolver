# ============================================================
# china-mirror-resolver / validate.ps1
# Validate baseline mirror reachability (Windows PowerShell)
# Usage: powershell -ExecutionPolicy Bypass -File validate.ps1 [-Tool <name>] [-Json]
#   Tool: pip|npm|conda|docker|go|rust|maven|homebrew|github|huggingface|yum|all
#   -Json: output machine-readable JSON
#   default: all
# ============================================================

param(
    [string]$Tool = "all",
    [switch]$Json
)

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$global:PASS = 0; $global:FAIL = 0
$global:jsonResults = @()

function Check-Url {
    param([string]$Name, [string]$Url, [string]$ExpectCode = "200")
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $r = Invoke-WebRequest -Uri $Url -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
        $sw.Stop()
        $code = $r.StatusCode
        $ms = $sw.ElapsedMilliseconds
        if ($code -eq [int]$ExpectCode -or $ExpectCode -eq "any") {
            $global:PASS++
            $status = "OK"
            if (-not $Json) {
                Write-Host "  [OK]   " -ForegroundColor Green -NoNewline
                Write-Host ("{0,-30} HTTP {1} | {2}ms" -f $Name, $code, $ms)
            }
        } else {
            $global:FAIL++
            $status = "FAIL"
            if (-not $Json) {
                Write-Host "  [FAIL] " -ForegroundColor Red -NoNewline
                Write-Host ("{0,-30} HTTP {1} | {2}ms" -f $Name, $code, $ms)
            }
        }
        $global:jsonResults += @{ name=$Name; url=$Url; status=$status; http_code="$code"; time_ms=$ms }
    } catch {
        $sw.Stop()
        $ms = $sw.ElapsedMilliseconds
        $errMsg = $_.Exception.Message
        if ($errMsg -match "401" -and $ExpectCode -eq "401") {
            $global:PASS++
            $status = "OK"
            if (-not $Json) {
                Write-Host "  [OK]   " -ForegroundColor Green -NoNewline
                Write-Host ("{0,-30} HTTP 401 (auth expected) | {1}ms" -f $Name, $ms)
            }
            $global:jsonResults += @{ name=$Name; url=$Url; status="OK"; http_code="401"; time_ms=$ms }
        } else {
            $global:FAIL++
            $status = "FAIL"
            $shortErr = $errMsg.Substring(0, [Math]::Min(80, $errMsg.Length))
            if (-not $Json) {
                Write-Host "  [FAIL] " -ForegroundColor Red -NoNewline
                Write-Host ("{0,-30} {1}" -f $Name, $shortErr)
            }
            $global:jsonResults += @{ name=$Name; url=$Url; status="FAIL"; http_code="0"; time_ms=$ms }
        }
    }
}

function Section {
    param([string]$Text)
    if (-not $Json) { Write-Host "`n--- $Text ---" -ForegroundColor Cyan }
}

# ---- pip ----
if ($Tool -eq "all" -or $Tool -eq "pip") {
    Section "pip"
    Check-Url "Tsinghua TUNA"  "https://pypi.tuna.tsinghua.edu.cn/simple/"
    Check-Url "Aliyun"         "https://mirrors.aliyun.com/pypi/simple/"
    Check-Url "USTC"           "https://pypi.mirrors.ustc.edu.cn/simple/"
    Check-Url "Tencent"        "https://mirrors.cloud.tencent.com/pypi/simple/"
}

# ---- npm ----
if ($Tool -eq "all" -or $Tool -eq "npm") {
    Section "npm"
    Check-Url "npmmirror"      "https://registry.npmmirror.com/"
    Check-Url "Huawei"         "https://repo.huaweicloud.com/repository/npm/"
}

# ---- conda ----
if ($Tool -eq "all" -or $Tool -eq "conda") {
    Section "conda"
    Check-Url "Tsinghua Main"  "https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/"
    Check-Url "USTC"           "https://mirrors.ustc.edu.cn/anaconda/pkgs/main/"
    Check-Url "Aliyun"         "https://mirrors.aliyun.com/anaconda/pkgs/main/"
}

# ---- Docker ----
if ($Tool -eq "all" -or $Tool -eq "docker") {
    Section "Docker"
    Check-Url "1ms.run"        "https://docker.1ms.run/v2/"        "401"
    Check-Url "xuanyuan.me"    "https://docker.xuanyuan.me/v2/"    "401"
    Check-Url "daocloud.io"    "https://docker.m.daocloud.io/v2/"  "401"
    Check-Url "linkedbus"      "https://docker.linkedbus.com/v2/"  "401"
}

# ---- Go ----
if ($Tool -eq "all" -or $Tool -eq "go") {
    Section "Go"
    Check-Url "goproxy.cn"     "https://goproxy.cn/"
    Check-Url "goproxy.io"     "https://goproxy.io/"
}

# ---- Rust ----
if ($Tool -eq "all" -or $Tool -eq "rust") {
    Section "Rust"
    Check-Url "USTC crates"    "https://mirrors.ustc.edu.cn/crates.io-index/"
    Check-Url "Tsinghua"       "https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/"
    Check-Url "RsProxy.cn"    "https://rsproxy.cn/"
}

# ---- Maven ----
if ($Tool -eq "all" -or $Tool -eq "maven") {
    Section "Maven"
    Check-Url "Aliyun Public" "https://maven.aliyun.com/repository/public/"
    Check-Url "Huawei"        "https://repo.huaweicloud.com/repository/maven/" "any"
}

# ---- Homebrew ----
if ($Tool -eq "all" -or $Tool -eq "homebrew") {
    Section "Homebrew"
    Check-Url "Tsinghua Bottles" "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/"
    Check-Url "USTC Bottles"     "https://mirrors.ustc.edu.cn/homebrew-bottles/"
}

# ---- GitHub ----
if ($Tool -eq "all" -or $Tool -eq "github") {
    Section "GitHub Accelerator"
    Check-Url "ghfast.top"     "https://ghfast.top/"
    Check-Url "gh-proxy.com"   "https://gh-proxy.com/"
    Check-Url "ghp.ci"         "https://ghp.ci/"
}

# ---- HuggingFace ----
if ($Tool -eq "all" -or $Tool -eq "huggingface") {
    Section "HuggingFace"
    Check-Url "hf-mirror.com"  "https://hf-mirror.com/"
}

# ---- yum/dnf ----
if ($Tool -eq "all" -or $Tool -eq "yum") {
    Section "yum/dnf"
    Check-Url "Tsinghua CentOS" "https://mirrors.tuna.tsinghua.edu.cn/centos/"
    Check-Url "Aliyun CentOS"   "https://mirrors.aliyun.com/centos/"
    Check-Url "USTC CentOS"     "https://mirrors.ustc.edu.cn/centos/"
}

# ---- Output ----
if ($Json) {
    $global:jsonResults | ConvertTo-Json -Depth 3
} else {
    $total = $global:PASS + $global:FAIL
    Write-Host ""
    Write-Host ("=" * 50) -ForegroundColor Cyan
    Write-Host ("  Total: {0} | PASS: {1} | FAIL: {2}" -f $total, $global:PASS, $global:FAIL)
    Write-Host ("=" * 50) -ForegroundColor Cyan
}
