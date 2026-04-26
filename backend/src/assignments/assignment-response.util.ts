import { AssignmentDocument } from "../notifications/schemas/assignment.schema";

export function mapAssignmentAttachment(att: {
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

function lessonIdOf(assignment: AssignmentDocument): string | undefined {
  const lid = assignment.lessonId as any;
  if (!lid) return undefined;
  if (typeof lid === "object" && lid._id != null) return lid._id.toString();
  return lid.toString();
}

export function mapAssignmentToJson(assignment: AssignmentDocument) {
  const lid = assignment.lessonId as any;
  const lesson =
    lid && typeof lid === "object" && lid.title != null
      ? {
          id: lid._id?.toString(),
          title: lid.title,
        }
      : null;
  return {
    id: assignment._id.toString(),
    classId: assignment.classId.toString(),
    teacherId: assignment.teacherId.toString(),
    lessonId: lessonIdOf(assignment),
    lesson,
    title: assignment.title,
    description: assignment.description,
    dueDate: assignment.dueDate,
    isActive: assignment.isActive,
    attachments: (assignment.attachments || []).map(mapAssignmentAttachment),
    createdAt: assignment.createdAt,
    updatedAt: assignment.updatedAt,
  };
}
