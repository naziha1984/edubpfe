#!/bin/bash

# EduBridge AuthModule 测试脚本
# 使用方法: ./test-auth.sh

BASE_URL="http://localhost:3000/api"

echo "========================================="
echo "EduBridge AuthModule 测试"
echo "========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 注册新用户
echo -e "${YELLOW}1. 注册新用户 (PARENT)${NC}"
REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "parent@example.com",
    "password": "password123",
    "firstName": "John",
    "lastName": "Doe"
  }')

if echo "$REGISTER_RESPONSE" | grep -q "access_token"; then
  echo -e "${GREEN}✅ 注册成功${NC}"
  TOKEN=$(echo $REGISTER_RESPONSE | jq -r '.access_token')
  echo "Token: ${TOKEN:0:50}..."
else
  echo -e "${RED}❌ 注册失败${NC}"
  echo "$REGISTER_RESPONSE" | jq
  exit 1
fi
echo ""

# 2. 获取当前用户信息
echo -e "${YELLOW}2. 获取当前用户信息${NC}"
ME_RESPONSE=$(curl -s -X GET "$BASE_URL/auth/me" \
  -H "Authorization: Bearer $TOKEN")

if echo "$ME_RESPONSE" | grep -q "email"; then
  echo -e "${GREEN}✅ 获取用户信息成功${NC}"
  echo "$ME_RESPONSE" | jq
else
  echo -e "${RED}❌ 获取用户信息失败${NC}"
  echo "$ME_RESPONSE" | jq
fi
echo ""

# 3. 登录 ADMIN
echo -e "${YELLOW}3. 登录 ADMIN${NC}"
ADMIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@edubridge.com",
    "password": "admin123"
  }')

if echo "$ADMIN_RESPONSE" | grep -q "access_token"; then
  echo -e "${GREEN}✅ ADMIN 登录成功${NC}"
  ADMIN_TOKEN=$(echo $ADMIN_RESPONSE | jq -r '.access_token')
  echo "Admin Token: ${ADMIN_TOKEN:0:50}..."
else
  echo -e "${RED}❌ ADMIN 登录失败${NC}"
  echo "$ADMIN_RESPONSE" | jq
  exit 1
fi
echo ""

# 4. 测试 ADMIN 端点
echo -e "${YELLOW}4. 测试 ADMIN 专用端点${NC}"
ADMIN_ENDPOINT_RESPONSE=$(curl -s -X GET "$BASE_URL/admin-only" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

if echo "$ADMIN_ENDPOINT_RESPONSE" | grep -q "admin-only"; then
  echo -e "${GREEN}✅ ADMIN 端点访问成功${NC}"
  echo "$ADMIN_ENDPOINT_RESPONSE" | jq
else
  echo -e "${RED}❌ ADMIN 端点访问失败${NC}"
  echo "$ADMIN_ENDPOINT_RESPONSE" | jq
fi
echo ""

# 5. 使用 PARENT token 测试 ADMIN 端点（应该失败）
echo -e "${YELLOW}5. 使用 PARENT token 访问 ADMIN 端点（应该失败）${NC}"
PARENT_ADMIN_RESPONSE=$(curl -s -X GET "$BASE_URL/admin-only" \
  -H "Authorization: Bearer $TOKEN")

if echo "$PARENT_ADMIN_RESPONSE" | grep -q "Forbidden"; then
  echo -e "${GREEN}✅ 权限验证正确（返回 403）${NC}"
  echo "$PARENT_ADMIN_RESPONSE" | jq
else
  echo -e "${RED}❌ 权限验证失败${NC}"
  echo "$PARENT_ADMIN_RESPONSE" | jq
fi
echo ""

# 6. 登录 TEACHER
echo -e "${YELLOW}6. 登录 TEACHER${NC}"
TEACHER_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "teacher@edubridge.com",
    "password": "teacher123"
  }')

if echo "$TEACHER_RESPONSE" | grep -q "access_token"; then
  echo -e "${GREEN}✅ TEACHER 登录成功${NC}"
  TEACHER_TOKEN=$(echo $TEACHER_RESPONSE | jq -r '.access_token')
  echo "Teacher Token: ${TEACHER_TOKEN:0:50}..."
else
  echo -e "${RED}❌ TEACHER 登录失败${NC}"
  echo "$TEACHER_RESPONSE" | jq
  exit 1
fi
echo ""

# 7. 测试 TEACHER 或 ADMIN 端点
echo -e "${YELLOW}7. 测试 TEACHER 或 ADMIN 端点${NC}"
TEACHER_ENDPOINT_RESPONSE=$(curl -s -X GET "$BASE_URL/teacher-or-admin" \
  -H "Authorization: Bearer $TEACHER_TOKEN")

if echo "$TEACHER_ENDPOINT_RESPONSE" | grep -q "teacher-or-admin"; then
  echo -e "${GREEN}✅ TEACHER 端点访问成功${NC}"
  echo "$TEACHER_ENDPOINT_RESPONSE" | jq
else
  echo -e "${RED}❌ TEACHER 端点访问失败${NC}"
  echo "$TEACHER_ENDPOINT_RESPONSE" | jq
fi
echo ""

echo "========================================="
echo -e "${GREEN}✅ 所有测试完成！${NC}"
echo "========================================="
