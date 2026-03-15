# EduBridge KidsModule 测试脚本 (PowerShell)
# 使用方法: .\test-kids.ps1

$BASE_URL = "http://localhost:3000/api"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "EduBridge KidsModule 测试" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# 1. 注册 Parent 1
Write-Host "1. 注册 Parent 1" -ForegroundColor Yellow
$parent1Body = @{
    email = "parent1@example.com"
    password = "password123"
    firstName = "Parent"
    lastName = "One"
} | ConvertTo-Json

try {
    $parent1Response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" `
        -Method Post `
        -ContentType "application/json" `
        -Body $parent1Body
    
    Write-Host "✅ Parent 1 注册成功" -ForegroundColor Green
    $PARENT1_TOKEN = $parent1Response.access_token
    Write-Host "Token: $($PARENT1_TOKEN.Substring(0, [Math]::Min(50, $PARENT1_TOKEN.Length)))..." -ForegroundColor Gray
} catch {
    Write-Host "❌ Parent 1 注册失败" -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}
Write-Host ""

# 2. 注册 Parent 2
Write-Host "2. 注册 Parent 2" -ForegroundColor Yellow
$parent2Body = @{
    email = "parent2@example.com"
    password = "password123"
    firstName = "Parent"
    lastName = "Two"
} | ConvertTo-Json

try {
    $parent2Response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" `
        -Method Post `
        -ContentType "application/json" `
        -Body $parent2Body
    
    Write-Host "✅ Parent 2 注册成功" -ForegroundColor Green
    $PARENT2_TOKEN = $parent2Response.access_token
    Write-Host "Token: $($PARENT2_TOKEN.Substring(0, [Math]::Min(50, $PARENT2_TOKEN.Length)))..." -ForegroundColor Gray
} catch {
    Write-Host "❌ Parent 2 注册失败" -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}
Write-Host ""

# 3. Parent 1 创建 Kid
Write-Host "3. Parent 1 创建 Kid" -ForegroundColor Yellow
$kid1Body = @{
    firstName = "Alice"
    lastName = "One"
    dateOfBirth = "2015-05-15"
    grade = "3rd Grade"
    school = "Elementary School"
} | ConvertTo-Json

$parent1Headers = @{
    Authorization = "Bearer $PARENT1_TOKEN"
}

try {
    $kid1Response = Invoke-RestMethod -Uri "$BASE_URL/kids" `
        -Method Post `
        -ContentType "application/json" `
        -Headers $parent1Headers `
        -Body $kid1Body
    
    Write-Host "✅ Kid 1 创建成功" -ForegroundColor Green
    $KID1_ID = $kid1Response.id
    Write-Host "Kid 1 ID: $KID1_ID" -ForegroundColor Gray
    $kid1Response | ConvertTo-Json
} catch {
    Write-Host "❌ Kid 1 创建失败" -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}
Write-Host ""

# 4. Parent 1 查看自己的 Kids
Write-Host "4. Parent 1 查看自己的 Kids" -ForegroundColor Yellow
try {
    $parent1Kids = Invoke-RestMethod -Uri "$BASE_URL/kids" `
        -Method Get `
        -Headers $parent1Headers
    
    Write-Host "✅ Parent 1 有 $($parent1Kids.Count) 个 kid(s)" -ForegroundColor Green
    $parent1Kids | ConvertTo-Json
} catch {
    Write-Host "❌ 获取 Parent 1 的 kids 失败" -ForegroundColor Red
    Write-Host $_.Exception.Message
}
Write-Host ""

# 5. Parent 2 创建 Kid
Write-Host "5. Parent 2 创建 Kid" -ForegroundColor Yellow
$kid2Body = @{
    firstName = "Bob"
    lastName = "Two"
    dateOfBirth = "2016-06-20"
    grade = "2nd Grade"
    school = "Elementary School"
} | ConvertTo-Json

$parent2Headers = @{
    Authorization = "Bearer $PARENT2_TOKEN"
}

try {
    $kid2Response = Invoke-RestMethod -Uri "$BASE_URL/kids" `
        -Method Post `
        -ContentType "application/json" `
        -Headers $parent2Headers `
        -Body $kid2Body
    
    Write-Host "✅ Kid 2 创建成功" -ForegroundColor Green
    $KID2_ID = $kid2Response.id
    Write-Host "Kid 2 ID: $KID2_ID" -ForegroundColor Gray
    $kid2Response | ConvertTo-Json
} catch {
    Write-Host "❌ Kid 2 创建失败" -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 1
}
Write-Host ""

# 6. Parent 2 查看自己的 Kids
Write-Host "6. Parent 2 查看自己的 Kids" -ForegroundColor Yellow
try {
    $parent2Kids = Invoke-RestMethod -Uri "$BASE_URL/kids" `
        -Method Get `
        -Headers $parent2Headers
    
    Write-Host "✅ Parent 2 有 $($parent2Kids.Count) 个 kid(s)" -ForegroundColor Green
    $parent2Kids | ConvertTo-Json
} catch {
    Write-Host "❌ 获取 Parent 2 的 kids 失败" -ForegroundColor Red
    Write-Host $_.Exception.Message
}
Write-Host ""

# 7. 验证 Parent 1 看不到 Parent 2 的 Kids
Write-Host "7. 验证 Parent 1 看不到 Parent 2 的 Kids" -ForegroundColor Yellow
try {
    $parent1KidsAgain = Invoke-RestMethod -Uri "$BASE_URL/kids" `
        -Method Get `
        -Headers $parent1Headers
    
    $kid2InParent1List = $parent1KidsAgain | Where-Object { $_.id -eq $KID2_ID }
    if ($null -eq $kid2InParent1List) {
        Write-Host "✅ Ownership 验证通过：Parent 1 看不到 Parent 2 的 kid" -ForegroundColor Green
    } else {
        Write-Host "❌ Ownership 验证失败：Parent 1 看到了 Parent 2 的 kid" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ 验证失败" -ForegroundColor Red
    Write-Host $_.Exception.Message
}
Write-Host ""

# 8. Parent 1 尝试更新 Parent 2 的 Kid（应该失败）
Write-Host "8. Parent 1 尝试更新 Parent 2 的 Kid（应该失败）" -ForegroundColor Yellow
$updateBody = @{
    firstName = "Hacked"
} | ConvertTo-Json

try {
    $updateResponse = Invoke-RestMethod -Uri "$BASE_URL/kids/$KID2_ID" `
        -Method Put `
        -ContentType "application/json" `
        -Headers $parent1Headers `
        -Body $updateBody
    
    Write-Host "❌ Ownership check 失败（应该返回 403）" -ForegroundColor Red
    $updateResponse | ConvertTo-Json
} catch {
    if ($_.Exception.Response.StatusCode -eq 403) {
        Write-Host "✅ Ownership check 通过（返回 403）" -ForegroundColor Green
    } else {
        Write-Host "❌ 意外错误" -ForegroundColor Red
        Write-Host $_.Exception.Message
    }
}
Write-Host ""

# 9. Parent 1 尝试删除 Parent 2 的 Kid（应该失败）
Write-Host "9. Parent 1 尝试删除 Parent 2 的 Kid（应该失败）" -ForegroundColor Yellow
try {
    $deleteResponse = Invoke-RestMethod -Uri "$BASE_URL/kids/$KID2_ID" `
        -Method Delete `
        -Headers $parent1Headers
    
    Write-Host "❌ Ownership check 失败（应该返回 403）" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 403) {
        Write-Host "✅ Ownership check 通过（返回 403）" -ForegroundColor Green
    } else {
        Write-Host "❌ 意外错误" -ForegroundColor Red
        Write-Host $_.Exception.Message
    }
}
Write-Host ""

# 10. Parent 1 更新自己的 Kid
Write-Host "10. Parent 1 更新自己的 Kid" -ForegroundColor Yellow
$updateBody = @{
    firstName = "Alice Updated"
    grade = "4th Grade"
} | ConvertTo-Json

try {
    $updateResponse = Invoke-RestMethod -Uri "$BASE_URL/kids/$KID1_ID" `
        -Method Put `
        -ContentType "application/json" `
        -Headers $parent1Headers `
        -Body $updateBody
    
    Write-Host "✅ Kid 更新成功" -ForegroundColor Green
    $updateResponse | ConvertTo-Json
} catch {
    Write-Host "❌ Kid 更新失败" -ForegroundColor Red
    Write-Host $_.Exception.Message
}
Write-Host ""

# 11. Parent 1 删除自己的 Kid
Write-Host "11. Parent 1 删除自己的 Kid" -ForegroundColor Yellow
try {
    $deleteResponse = Invoke-WebRequest -Uri "$BASE_URL/kids/$KID1_ID" `
        -Method Delete `
        -Headers $parent1Headers
    
    if ($deleteResponse.StatusCode -eq 204) {
        Write-Host "✅ Kid 删除成功（返回 204）" -ForegroundColor Green
    } else {
        Write-Host "❌ Kid 删除失败（返回 $($deleteResponse.StatusCode)）" -ForegroundColor Red
    }
} catch {
    if ($_.Exception.Response.StatusCode -eq 204) {
        Write-Host "✅ Kid 删除成功（返回 204）" -ForegroundColor Green
    } else {
        Write-Host "❌ Kid 删除失败" -ForegroundColor Red
        Write-Host $_.Exception.Message
    }
}
Write-Host ""

# 12. 验证 Kid 已删除
Write-Host "12. 验证 Kid 已删除" -ForegroundColor Yellow
try {
    $parent1KidsFinal = Invoke-RestMethod -Uri "$BASE_URL/kids" `
        -Method Get `
        -Headers $parent1Headers
    
    if ($parent1KidsFinal.Count -eq 0) {
        Write-Host "✅ Kid 已成功删除（列表为空）" -ForegroundColor Green
    } else {
        Write-Host "❌ Kid 删除验证失败（列表中还有 $($parent1KidsFinal.Count) 个 kid）" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ 验证失败" -ForegroundColor Red
    Write-Host $_.Exception.Message
}
Write-Host ""

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "✅ 所有测试完成！" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
