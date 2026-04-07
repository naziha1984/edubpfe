import { LessonDocument } from './schemas/lesson.schema';

export function mapLessonAttachment(att: {
  originalName: string;
  mimeType: string;
  size: number;
  urlPath: string;
}) {
  return {
    originalName: att.originalName,
    mimeType: att.mimeType,
    size: att.size,
    url: `/api/uploads/${att.urlPath}`,
  };
}

export function mapLessonToJson(
  lesson: LessonDocument,
  opts?: { quizQuestionCount?: number },
) {
  return {
    id: lesson._id.toString(),
    subjectId: lesson.subjectId.toString(),
    teacherId: lesson.teacherId?.toString(),
    classId: lesson.classId?.toString(),
    title: lesson.title,
    description: lesson.description,
    content: lesson.content,
    order: lesson.order,
    level: lesson.level,
    language: lesson.language,
    isActive: lesson.isActive,
    attachments: (lesson.attachments || []).map(mapLessonAttachment),
    createdAt: lesson.createdAt,
    updatedAt: lesson.updatedAt,
    quizQuestionCount: opts?.quizQuestionCount ?? 0,
  };
}
