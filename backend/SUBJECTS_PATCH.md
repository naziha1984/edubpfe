# Subjects/Lessons 完整补丁总结

## 📦 新增文件

```
backend/src/subjects/
├── schemas/
│   ├── subject.schema.ts       # Subject Mongoose schema
│   └── lesson.schema.ts        # Lesson Mongoose schema
├── dto/
│   ├── create-subject.dto.ts   # 创建科目 DTO
│   ├── update-subject.dto.ts   # 更新科目 DTO
│   ├── create-lesson.dto.ts    # 创建课程 DTO
│   └── update-lesson.dto.ts    # 更新课程 DTO
├── subjects.service.ts         # Subjects 服务
├── lessons.service.ts          # Lessons 服务
├── subjects.controller.ts      # Subjects 控制器
├── lessons.controller.ts       # Lessons 控制器
└── subjects.module.ts          # Subjects 模块
```

## 🔧 功能实现

### 1. Subject Schema

**字段:**
- `name`: 科目名称（必填，唯一索引）
- `description`: 描述（可选）
- `code`: 科目代码（可选）
- `isActive`: 是否活跃（默认 true）
- `timestamps`: 自动添加 createdAt 和 updatedAt

**唯一索引:**
- `name`: 确保科目名称唯一

### 2. Lesson Schema

**字段:**
- `subjectId`: 所属科目（ObjectId 引用）
- `title`: 课程标题（必填）
- `description`: 描述（可选）
- `content`: 课程内容（可选）
- `order`: 排序（可选）
- `isActive`: 是否活跃（默认 true）
- `timestamps`: 自动添加 createdAt 和 updatedAt

**唯一索引:**
- 复合唯一索引: `{ subjectId: 1, title: 1 }` - 确保同一科目内标题唯一

### 3. 公开端点

#### GET /api/subjects
- 返回所有活跃科目
- 按名称排序
- 无需认证

#### GET /api/subjects/:id/lessons
- 返回某个科目的所有活跃课程
- 按 order 和 createdAt 排序
- 无需认证
- 验证科目是否存在

### 4. Admin 端点

#### Subjects CRUD
- **POST /api/subjects**: 创建科目（需要 ADMIN）
- **GET /api/subjects/admin/:id**: 获取科目详情（包括非活跃，需要 ADMIN）
- **PUT /api/subjects/:id**: 更新科目（需要 ADMIN）
- **DELETE /api/subjects/:id**: 删除科目（需要 ADMIN）

#### Lessons CRUD
- **POST /api/lessons**: 创建课程（需要 ADMIN）
- **GET /api/lessons/:id**: 获取课程详情（需要 ADMIN）
- **PUT /api/lessons/:id**: 更新课程（需要 ADMIN）
- **DELETE /api/lessons/:id**: 删除课程（需要 ADMIN）

## 🔒 安全特性

### 1. 角色验证
- 所有 Admin 端点需要 ADMIN 角色
- 使用 `@Roles(UserRole.ADMIN)` 装饰器
- 使用 `RolesGuard` 验证权限

### 2. 唯一索引保护
- Subject name 唯一索引防止重复
- Lesson (subjectId, title) 复合唯一索引防止同一科目内重复标题
- 捕获 MongoDB 11000 错误代码并返回 409 Conflict

### 3. DTO 验证
- 使用 `class-validator` 验证输入
- 必填字段验证
- 类型验证（MongoId, String, Number, Boolean）
- 自动返回 400 Bad Request 如果验证失败

### 4. 数据验证
- 创建/更新课程时验证 subjectId 是否存在
- 更新课程时如果更改 subjectId，验证新 subjectId 是否存在

## 📝 DTO 验证规则

### CreateSubjectDto
- `name`: 必填，字符串
- `description`: 可选，字符串
- `code`: 可选，字符串
- `isActive`: 可选，布尔值

### UpdateSubjectDto
- 所有字段可选
- 类型验证与 CreateSubjectDto 相同

### CreateLessonDto
- `subjectId`: 必填，MongoId 格式
- `title`: 必填，字符串
- `description`: 可选，字符串
- `content`: 可选，字符串
- `order`: 可选，数字
- `isActive`: 可选，布尔值

### UpdateLessonDto
- 所有字段可选
- `subjectId`: 如果提供，必须是 MongoId 格式
- 类型验证与 CreateLessonDto 相同

## 🚀 API 端点总结

### 公开端点

| 方法 | 路径 | 描述 | 认证 |
|------|------|------|------|
| GET | /api/subjects | 获取所有活跃科目 | 无需 |
| GET | /api/subjects/:id/lessons | 获取科目课程 | 无需 |

### Admin 端点

| 方法 | 路径 | 描述 | 认证 |
|------|------|------|------|
| POST | /api/subjects | 创建科目 | ADMIN |
| GET | /api/subjects/admin/:id | 获取科目详情 | ADMIN |
| PUT | /api/subjects/:id | 更新科目 | ADMIN |
| DELETE | /api/subjects/:id | 删除科目 | ADMIN |
| POST | /api/lessons | 创建课程 | ADMIN |
| GET | /api/lessons/:id | 获取课程详情 | ADMIN |
| PUT | /api/lessons/:id | 更新课程 | ADMIN |
| DELETE | /api/lessons/:id | 删除课程 | ADMIN |

## ✅ 测试场景

- [x] 公开端点无需认证
- [x] 获取所有活跃科目
- [x] 获取科目课程
- [x] ADMIN 创建科目
- [x] ADMIN 更新科目
- [x] ADMIN 删除科目
- [x] ADMIN 创建课程
- [x] ADMIN 更新课程
- [x] ADMIN 删除课程
- [x] 重复科目名称被拒绝（409）
- [x] 同一科目内重复标题被拒绝（409）
- [x] 不同科目可以有相同标题
- [x] 非 ADMIN 用户无法访问 Admin 端点（403）
- [x] DTO 验证工作正常（400）
- [x] 无效 ID 返回 404

## 🔍 技术细节

### 唯一索引实现

```typescript
// Subject schema
SubjectSchema.index({ name: 1 }, { unique: true });

// Lesson schema
LessonSchema.index({ subjectId: 1, title: 1 }, { unique: true });
```

### 错误处理

```typescript
try {
  const subject = new this.subjectModel(createSubjectDto);
  return await subject.save();
} catch (error: any) {
  if (error.code === 11000) {
    throw new ConflictException('Subject with this name already exists');
  }
  throw error;
}
```

### 排序

```typescript
// Subjects: 按名称排序
.find({ isActive: true }).sort({ name: 1 })

// Lessons: 按 order 和创建时间排序
.find({ subjectId, isActive: true }).sort({ order: 1, createdAt: 1 })
```

## 📚 相关文档

- `SUBJECTS_TEST.md`: 详细测试指南
- `AUTH_TEST.md`: 认证相关测试
- `AUTH_PATCH.md`: AuthModule 补丁文档

## ⚠️ 注意事项

1. **唯一索引**: 在数据库级别强制执行，确保数据完整性
2. **软删除**: 使用 `isActive` 字段标记删除，实际数据保留
3. **排序**: 科目按名称，课程按 order 和创建时间
4. **验证**: 创建/更新课程时验证 subjectId 存在
5. **权限**: 所有 Admin 操作需要 ADMIN 角色
