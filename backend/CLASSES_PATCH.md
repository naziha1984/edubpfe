# ClassesModule 完整补丁总结

## 📦 新增文件

```
backend/src/classes/
├── schemas/
│   ├── class.schema.ts          # Class schema（唯一 classCode）
│   └── class-membership.schema.ts # ClassMembership schema（复合唯一索引）
├── dto/
│   ├── create-class.dto.ts     # 创建班级 DTO
│   └── join-class.dto.ts        # 加入班级 DTO
├── classes.service.ts           # Classes 服务（严格所有权检查）
├── classes.controller.ts        # Teacher 班级控制器
├── join.controller.ts           # Parent 加入班级控制器
└── classes.module.ts            # Classes 模块
```

## 🔧 功能实现

### 1. Class Schema

**字段:**
- `teacherId`: Teacher 引用（ObjectId）
- `name`: 班级名称（必填）
- `description`: 描述（可选）
- `classCode`: 班级代码（必填，唯一，自动生成）
- `isActive`: 是否活跃（默认 true）
- `timestamps`: 自动添加 createdAt 和 updatedAt

**唯一索引:**
- `classCode`: 确保班级代码唯一

### 2. ClassMembership Schema

**字段:**
- `classId`: Class 引用（ObjectId）
- `kidId`: Kid 引用（ObjectId）
- `isActive`: 是否活跃（默认 true）
- `timestamps`: 自动添加 createdAt 和 updatedAt

**唯一索引:**
- 复合唯一索引: `{ classId: 1, kidId: 1 }` - 确保每个 kid 在每个 class 中只有一个成员记录

### 3. API 端点

#### Teacher 端点（需要 TEACHER 角色）

**POST /api/teacher/classes**
- 创建班级
- 自动生成唯一的 6 位字母数字 classCode
- 返回包含 classCode 的班级信息

**GET /api/teacher/classes**
- 获取教师的所有班级
- 按创建时间倒序排列

**GET /api/teacher/classes/:classId**
- 获取班级详情（仅所有者）
- **严格所有权检查**: 只能查看自己的班级
- 包含成员列表

#### Parent 端点（需要 PARENT 角色）

**POST /api/classes/join**
- 加入班级
- 需要 classCode 和 kidId
- **严格所有权检查**: parent 必须拥有该 kid
- 如果 kid 已加入，返回 409 Conflict

## 🔒 严格所有权检查

### 1. Teacher 查看班级详情

```typescript
// 验证班级是否属于教师
const isOwner = await this.classesService.checkOwnership(classId, teacherId);
if (!isOwner) {
  throw new ForbiddenException('You can only view your own classes');
}
```

### 2. Parent 加入班级

```typescript
// 验证 parent 拥有该 kid
const kid = await this.kidsService.findOneById(joinClassDto.kidId);
if (kid.parentId.toString() !== user.id) {
  throw new ForbiddenException('You can only join classes for your own kids');
}
```

### 3. 获取班级成员

```typescript
// 只有班级所有者可以查看成员
const isOwner = await this.checkOwnership(classId, teacherId);
if (!isOwner) {
  throw new ForbiddenException('You can only view members of your own classes');
}
```

## 📝 业务逻辑

### 1. classCode 生成

- 生成 6 位字母数字代码（A-Z, 0-9）
- 检查唯一性，最多尝试 10 次
- 如果无法生成唯一代码，抛出 ConflictException

### 2. 加入班级

- 通过 classCode 查找班级
- 验证班级存在且活跃
- 检查 kid 是否已是成员
- 如果已加入且活跃，返回 409
- 如果已加入但不活跃，重新激活
- 如果未加入，创建新成员记录

### 3. 成员管理

- 每个 kid 在每个 class 中只有一个成员记录
- 使用复合唯一索引防止重复
- 支持软删除（isActive = false）

## 🚀 API 端点总结

| 方法 | 路径 | 描述 | 认证 | 所有权检查 |
|------|------|------|------|-----------|
| POST | /api/teacher/classes | 创建班级 | TEACHER | ✅ teacherId |
| GET | /api/teacher/classes | 获取所有班级 | TEACHER | ✅ teacherId |
| GET | /api/teacher/classes/:classId | 获取班级详情 | TEACHER | ✅ 班级所有者 |
| POST | /api/classes/join | 加入班级 | PARENT | ✅ kid 所有权 |

## ✅ 测试场景

- [x] Teacher 可以创建班级
- [x] 班级创建时自动生成唯一的 classCode
- [x] Teacher 可以查看自己的所有班级
- [x] Teacher 可以查看自己班级的详情
- [x] Teacher 不能查看其他 Teacher 的班级（403）
- [x] Parent 可以为自己的 kid 加入班级
- [x] Parent 不能为其他 Parent 的 kid 加入班级（403）
- [x] 重复加入班级被拒绝（409）
- [x] 无效的 classCode 返回 404
- [x] 班级详情包含成员列表

## 🔍 技术细节

### classCode 生成算法

```typescript
generateClassCode(): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}
```

### 唯一性检查

```typescript
let classCode: string;
let isUnique = false;
let attempts = 0;
const maxAttempts = 10;

while (!isUnique && attempts < maxAttempts) {
  classCode = this.generateClassCode();
  const existing = await this.classModel.findOne({ classCode }).exec();
  if (!existing) {
    isUnique = true;
  }
  attempts++;
}
```

### 成员关系检查

```typescript
// 检查是否已是成员
const existingMembership = await this.classMembershipModel
  .findOne({
    classId: classDoc._id,
    kidId: new Types.ObjectId(joinClassDto.kidId),
  })
  .exec();

if (existingMembership && existingMembership.isActive) {
  throw new ConflictException('Kid is already a member of this class');
}
```

## 📚 相关文档

- `CLASSES_TEST.md`: 详细测试指南
- `KIDS_TEST.md`: Kids 模块测试
- `AUTH_TEST.md`: 认证模块测试

## ⚠️ 注意事项

1. **classCode 生成**: 自动生成 6 位字母数字代码
2. **唯一性**: classCode 在数据库中唯一，使用唯一索引
3. **所有权检查**: 所有操作都严格验证所有权
4. **成员关系**: 每个 kid 在每个 class 中只有一个成员记录
5. **重复加入**: 如果 kid 已加入，返回 409 Conflict
6. **软删除**: 支持通过 isActive 字段软删除成员关系

## 🔐 安全保证

1. **角色验证**: Teacher 端点需要 TEACHER 角色，Parent 端点需要 PARENT 角色
2. **所有权验证**: 严格检查资源所有权
3. **kid 所有权**: Parent 只能为自己的 kids 加入班级
4. **班级所有权**: Teacher 只能查看自己的班级
5. **数据隔离**: 每个用户只能访问自己的数据
