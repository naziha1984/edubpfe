import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document, Types } from "mongoose";

/** Pièce jointe (fichiers hébergés sous /api/uploads/assignments/) */
@Schema({ _id: false })
export class AssignmentAttachment {
  @Prop({ required: true })
  originalName: string;

  @Prop({ required: true })
  storedName: string;

  @Prop({ required: true })
  mimeType: string;

  @Prop({ required: true })
  size: number;

  /** Chemin relatif au dossier uploads (ex. assignments/abc.pdf) */
  @Prop({ required: true })
  urlPath: string;
}

export const AssignmentAttachmentSchema =
  SchemaFactory.createForClass(AssignmentAttachment);

export type AssignmentDocument = Assignment &
  Document & {
    createdAt: Date;
    updatedAt: Date;
  };

@Schema({ timestamps: true })
export class Assignment {
  @Prop({ required: true, type: Types.ObjectId, ref: "Class" })
  classId: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: "User" })
  teacherId: Types.ObjectId;

  @Prop({ required: true })
  title: string;

  @Prop()
  description?: string;

  @Prop({ type: Types.ObjectId, ref: "Lesson" })
  lessonId?: Types.ObjectId;

  @Prop({ required: true, type: Date })
  dueDate: Date;

  @Prop({ default: true })
  isActive: boolean;

  @Prop({ type: [AssignmentAttachmentSchema], default: [] })
  attachments: AssignmentAttachment[];
}

export const AssignmentSchema = SchemaFactory.createForClass(Assignment);

// 索引用于查询
AssignmentSchema.index({ classId: 1, dueDate: 1 });
AssignmentSchema.index({ teacherId: 1 });
