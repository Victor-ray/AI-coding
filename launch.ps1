# 游戏启动脚本 - 狱火爬升
# 获取脚本所在目录
$script_dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$project_dir = $script_dir

# 查找 Godot 可执行文件
function Find-Godot {
    $candidates = @(
        (Join-Path $project_dir "Godot_v4.6.3-stable_win64.exe"),
        "E:\Computer_Softwares\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe",
        "F:\卡牌肉鸽\_godot\Godot_v4.3-stable_win64.exe",
        "$env:LOCALAPPDATA\Godot\Godot_v4.3-stable_win64.exe"
    )
    foreach ($path in $candidates) {
        $path = $path.Trim()
        if (Test-Path $path) {
            return $path
        }
    }
    return $null
}

$godot_exe = Find-Godot

if ($null -eq $godot_exe) {
    Write-Host "找不到 Godot_v4.6.3-stable_win64.exe" -ForegroundColor Red
    Write-Host "请从 https://godotengine.org 下载 Godot" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "启动狱火爬升..." -ForegroundColor Green
Write-Host "项目路径: $project_dir" -ForegroundColor Gray
Write-Host "Godot路径: $godot_exe" -ForegroundColor Gray

# 用双引号包裹路径，防止空格问题
Start-Process -FilePath """$godot_exe""" -ArgumentList "--path", """$project_dir""", "--editor"