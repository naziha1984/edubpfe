#!/bin/bash

# EduBridge KidsModule 测试脚本
# 使用方法: ./test-kids.sh

BASE_URL="http://localhost:3000/api"

echo "========================================="
echo "EduBridge KidsModule 测试"
echo "========================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 注册 Parent 1
echo -e "${YELLOW}1. 注册 Parent 1${NC}"
PARENT1_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "parent1@example.com",
    "password": "password123",
    "firstName": "Parent",
    "lastName": "One"
  }')

if echo "$PARENT1_RESPONSE" | grep -q "access_token"; then
  echo -e "${GREEN}✅ Parent 1 注册成功${NC}"
  PARENT1_TOKEN=$(echo $PARENT1_RESPONSE | jq -r '.access_token')
  echo "Token: ${PARENT1_TOKEN:0:50}..."
else
  echo -e "${RED}❌ Parent 1 注册失败${NC}"
  echo "$PARENT1_RESPONSE" | jq
  exit 1
fi
echo ""

# 2. 注册 Parent 2
echo -e "${YELLOW}2. 注册 Parent 2${NC}"
PARENT2_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "parent2@example.com",
    "password": "password123",
    "firstName": "Parent",
    "lastName": "Two"
  }')

if echo "$PARENT2_RESPONSE" | grep -q "access_token"; then
  echo -e "${GREEN}✅ Parent 2 注册成功${NC}"
  PARENT2_TOKEN=$(echo $PARENT2_RESPONSE | jq -r '.access_token')
  echo "Token: ${PARENT2_TOKEN:0:50}..."
else
  echo -e "${RED}❌ Parent 2 注册失败${NC}"
  echo "$PARENT2_RESPONSE" | jq
  exit 1
fi
echo ""

# 3. Parent 1 创建 Kid
echo -e "${YELLOW}3. Parent 1 创建 Kid${NC}"
KID1_RESPONSE=$(curl -s -X POST "$BASE_URL/kids" \
  -H "Authorization: Bearer $PARENT1_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Alice",
    "lastName": "One",
    "dateOfBirth": "2015-05-15",
    "grade": "3rd Grade",
    "school": "Elementary School"
  }')

if echo "$KID1_RESPONSE" | grep -q "id"; then
  echo -e "${GREEN}✅ Kid 1 创建成功${NC}"
  KID1_ID=$(echo $KID1_RESPONSE | jq -r '.id')
  echo "Kid 1 ID: $KID1_ID"
  echo "$KID1_RESPONSE" | jq
else
  echo -e "${RED}❌ Kid 1 创建失败${NC}"
  echo "$KID1_RESPONSE" | jq
  exit 1
fi
echo ""

# 4. Parent 1 查看自己的 Kids
echo -e "${YELLOW}4. Parent 1 查看自己的 Kids${NC}"
PARENT1_KIDS=$(curl -s -X GET "$BASE_URL/kids" \
  -H "Authorization: Bearer $PARENT1_TOKEN")

KID_COUNT=$(echo $PARENT1_KIDS | jq '. | length')
if [ "$KID_COUNT" -gt 0 ]; then
  echo -e "${GREEN}✅ Parent 1 有 $KID_COUNT 个 kid(s)${NC}"
  echo "$PARENT1_KIDS" | jq
else
  echo -e "${RED}❌ Parent 1 没有 kids${NC}"
fi
echo ""

# 5. Parent 2 创建 Kid
echo -e "${YELLOW}5. Parent 2 创建 Kid${NC}"
KID2_RESPONSE=$(curl -s -X POST "$BASE_URL/kids" \
  -H "Authorization: Bearer $PARENT2_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Bob",
    "lastName": "Two",
    "dateOfBirth": "2016-06-20",
    "grade": "2nd Grade",
    "school": "Elementary School"
  }')

if echo "$KID2_RESPONSE" | grep -q "id"; then
  echo -e "${GREEN}✅ Kid 2 创建成功${NC}"
  KID2_ID=$(echo $KID2_RESPONSE | jq -r '.id')
  echo "Kid 2 ID: $KID2_ID"
  echo "$KID2_RESPONSE" | jq
else
  echo -e "${RED}❌ Kid 2 创建失败${NC}"
  echo "$KID2_RESPONSE" | jq
  exit 1
fi
echo ""

# 6. Parent 2 查看自己的 Kids
echo -e "${YELLOW}6. Parent 2 查看自己的 Kids${NC}"
PARENT2_KIDS=$(curl -s -X GET "$BASE_URL/kids" \
  -H "Authorization: Bearer $PARENT2_TOKEN")

KID_COUNT=$(echo $PARENT2_KIDS | jq '. | length')
if [ "$KID_COUNT" -gt 0 ]; then
  echo -e "${GREEN}✅ Parent 2 有 $KID_COUNT 个 kid(s)${NC}"
  echo "$PARENT2_KIDS" | jq
else
  echo -e "${RED}❌ Parent 2 没有 kids${NC}"
fi
echo ""

# 7. 验证 Parent 1 看不到 Parent 2 的 Kids
echo -e "${YELLOW}7. 验证 Parent 1 看不到 Parent 2 的 Kids${NC}"
PARENT1_KIDS_AGAIN=$(curl -s -X GET "$BASE_URL/kids" \
  -H "Authorization: Bearer $PARENT1_TOKEN")

KID2_IN_PARENT1_LIST=$(echo $PARENT1_KIDS_AGAIN | jq -r ".[] | select(.id == \"$KID2_ID\") | .id")
if [ -z "$KID2_IN_PARENT1_LIST" ]; then
  echo -e "${GREEN}✅ Ownership 验证通过：Parent 1 看不到 Parent 2 的 kid${NC}"
else
  echo -e "${RED}❌ Ownership 验证失败：Parent 1 看到了 Parent 2 的 kid${NC}"
fi
echo ""

# 8. Parent 1 尝试更新 Parent 2 的 Kid（应该失败）
echo -e "${YELLOW}8. Parent 1 尝试更新 Parent 2 的 Kid（应该失败）${NC}"
UPDATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$BASE_URL/kids/$KID2_ID" \
  -H "Authorization: Bearer $PARENT1_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Hacked"
  }')

HTTP_CODE=$(echo "$UPDATE_RESPONSE" | tail -n1)
if [ "$HTTP_CODE" = "403" ]; then
  echo -e "${GREEN}✅ Ownership check 通过（返回 403）${NC}"
else
  echo -e "${RED}❌ Ownership check 失败（返回 $HTTP_CODE）${NC}"
  echo "$UPDATE_RESPONSE" | head -n-1 | jq
fi
echo ""

# 9. Parent 1 尝试删除 Parent 2 的 Kid（应该失败）
echo -e "${YELLOW}9. Parent 1 尝试删除 Parent 2 的 Kid（应该失败）${NC}"
DELETE_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$BASE_URL/kids/$KID2_ID" \
  -H "Authorization: Bearer $PARENT1_TOKEN")

HTTP_CODE=$(echo "$DELETE_RESPONSE" | tail -n1)
if [ "$HTTP_CODE" = "403" ]; then
  echo -e "${GREEN}✅ Ownership check 通过（返回 403）${NC}"
else
  echo -e "${RED}❌ Ownership check 失败（返回 $HTTP_CODE）${NC}"
fi
echo ""

# 10. Parent 1 更新自己的 Kid
echo -e "${YELLOW}10. Parent 1 更新自己的 Kid${NC}"
UPDATE_RESPONSE=$(curl -s -X PUT "$BASE_URL/kids/$KID1_ID" \
  -H "Authorization: Bearer $PARENT1_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Alice Updated",
    "grade": "4th Grade"
  }')

if echo "$UPDATE_RESPONSE" | grep -q "Alice Updated"; then
  echo -e "${GREEN}✅ Kid 更新成功${NC}"
  echo "$UPDATE_RESPONSE" | jq
else
  echo -e "${RED}❌ Kid 更新失败${NC}"
  echo "$UPDATE_RESPONSE" | jq
fi
echo ""

# 11. Parent 1 删除自己的 Kid
echo -e "${YELLOW}11. Parent 1 删除自己的 Kid${NC}"
DELETE_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$BASE_URL/kids/$KID1_ID" \
  -H "Authorization: Bearer $PARENT1_TOKEN")

HTTP_CODE=$(echo "$DELETE_RESPONSE" | tail -n1)
if [ "$HTTP_CODE" = "204" ]; then
  echo -e "${GREEN}✅ Kid 删除成功（返回 204）${NC}"
else
  echo -e "${RED}❌ Kid 删除失败（返回 $HTTP_CODE）${NC}"
fi
echo ""

# 12. 验证 Kid 已删除
echo -e "${YELLOW}12. 验证 Kid 已删除${NC}"
PARENT1_KIDS_FINAL=$(curl -s -X GET "$BASE_URL/kids" \
  -H "Authorization: Bearer $PARENT1_TOKEN")

KID_COUNT=$(echo $PARENT1_KIDS_FINAL | jq '. | length')
if [ "$KID_COUNT" -eq 0 ]; then
  echo -e "${GREEN}✅ Kid 已成功删除（列表为空）${NC}"
else
  echo -e "${RED}❌ Kid 删除验证失败（列表中还有 $KID_COUNT 个 kid）${NC}"
fi
echo ""

echo "========================================="
echo -e "${GREEN}✅ 所有测试完成！${NC}"
echo "========================================="
