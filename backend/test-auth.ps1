# EduBridge AuthModule 测试脚本 (PowerShell)
# 使用方法: .\test-auth.ps1

$BASE_URL = "http://localhost:3000/api"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "EduBridge AuthModule 测试" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# 1. 注册新用户
Write-Host "1. 注册新用户 (PARENT)" -ForegroundColor Yellow
$registerBody = @{
    email = "parent@example.com"
    password = "password123"
    firstName = "John"
    lastName = "Doe"
} | ConvertTo-Json

try {
    $registerResponse = Invoke-RestMethod -Uri "$BASE_URL/auth/register" `
        -Method Post `
        -ContentType "application/json" `
        -Body $registerBody
    
    Write-Host "✅ 注册成功" -ForegroundColor Green
    $TOKEN = $registerResponse.access_token
    Write-Host "Token: $($TOKEN.Substring(0, [Math]::Min(50, $TOKEN.Length)))..." -ForegroundColor Gray
} catch {
    Write-Host "❌ 注册失败" -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}
Write-Host ""

# 2. 获取当前用户信息
Write-Host "2. 获取当前用户信息" -ForegroundColor Yellow
$headers = @{
    Authorization = "Bearer $TOKEN"
}

try {
    $meResponse = Invoke-RestMethod -Uri "$BASE_URL/auth/me" `
        -Method Get `
        -Headers $headers
    
    Write-Host "✅ 获取用户信息成功" -ForegroundColor Green
    $meResponse | ConvertTo-Json
} catch {
    Write-Host "❌ 获取用户信息失败" -ForegroundColor Red
    Write-Host $_.Exception.Message
}
Write-Host ""

# 3. 登录 ADMIN
Write-Host "3. 登录 ADMIN" -ForegroundColor Yellow
$adminLoginBody = @{
    email = "admin@edubridge.com"
    password = "admin123"
} | ConvertTo-Json

try {
    $adminResponse = Invoke-RestMethod -Uri "$BASE_URL/auth/login" `
        -Method Post `
        -ContentType "application/json" `
        -Body $adminLoginBody
    
    Write-Host "✅ ADMIN 登录成功" -ForegroundColor Green
    $ADMIN_TOKEN = $adminResponse.access_token
    Write-Host "Admin Token: $($ADMIN_TOKEN.Substring(0, [Math]::Min(50, $ADMIN_TOKEN.Length)))..." -ForegroundColor Gray
} catch {
    Write-Host "❌ ADMIN 登录失败" -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}
Write-Host ""

# 4. 测试 ADMIN 端点
Write-Host "4. 测试 ADMIN 专用端点" -ForegroundColor Yellow
$adminHeaders = @{
    Authorization = "Bearer $ADMIN_TOKEN"
}

try {
    $adminEndpointResponse = Invoke-RestMethod -Uri "$BASE_URL/admin-only" `
        -Method Get `
        -Headers $adminHeaders
    
    Write-Host "✅ ADMIN 端点访问成功" -ForegroundColor Green
    $adminEndpointResponse | ConvertTo-Json
} catch {
    Write-Host "❌ ADMIN 端点访问失败" -ForegroundColor Red
    Write-Host $_.Exception.Message
}
Write-Host ""

# 5. 使用 PARENT token 测试 ADMIN 端点（应该失败）
Write-Host "5. 使用 PARENT token 访问 ADMIN 端点（应该失败）" -ForegroundColor Yellow
$parentHeaders = @{
    Authorization = "Bearer $TOKEN"
}

try {
    $parentAdminResponse = Invoke-RestMethod -Uri "$BASE_URL/admin-only" `
        -Method Get `
        -Headers $parentHeaders
    
    Write-Host "❌ 权限验证失败（应该返回 403）" -ForegroundColor Red
    $parentAdminResponse | ConvertTo-Json
} catch {
    if ($_.Exception.Response.StatusCode -eq 403) {
        Write-Host "✅ 权限验证正确（返回 403）" -ForegroundColor Green
    } else {
        Write-Host "❌ 意外错误" -ForegroundColor Red
        Write-Host $_.Exception.Message
    }
}
Write-Host ""

# 6. 登录 TEACHER
Write-Host "6. 登录 TEACHER" -ForegroundColor Yellow
$teacherLoginBody = @{
    email = "teacher@edubridge.com"
    password = "teacher123"
} | ConvertTo-Json

try {
    $teacherResponse = Invoke-RestMethod -Uri "$BASE_URL/auth/login" `
        -Method Post `
        -ContentType "application/json" `
        -Body $teacherLoginBody
    
    Write-Host "✅ TEACHER 登录成功" -ForegroundColor Green
    $TEACHER_TOKEN = $teacherResponse.access_token
    Write-Host "Teacher Token: $($TEACHER_TOKEN.Substring(0, [Math]::Min(50, $TEACHER_TOKEN.Length)))..." -ForegroundColor Gray
} catch {
    Write-Host "❌ TEACHER 登录失败" -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}
Write-Host ""

# 7. 测试 TEACHER 或 ADMIN 端点
Write-Host "7. 测试 TEACHER 或 ADMIN 端点" -ForegroundColor Yellow
$teacherHeaders = @{
    Authorization = "Bearer $TEACHER_TOKEN"
}

try {
    $teacherEndpointResponse = Invoke-RestMethod -Uri "$BASE_URL/teacher-or-admin" `
        -Method Get `
        -Headers $teacherHeaders
    
    Write-Host "✅ TEACHER 端点访问成功" -ForegroundColor Green
    $teacherEndpointResponse | ConvertTo-Json
} catch {
    Write-Host "❌ TEACHER 端点访问失败" -ForegroundColor Red
    Write-Host $_.Exception.Message
}
Write-Host ""

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "✅ 所有测试完成！" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
