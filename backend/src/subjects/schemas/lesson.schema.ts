import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type LessonDocument = Lesson &
  Document & {
    createdAt: Date;
    updatedAt: Date;
  };

@Schema({ timestamps: true })
export class LessonAttachment {
  @Prop({ required: true })
  originalName: string;

  @Prop({ required: true })
  storedName: string;

  @Prop({ required: true })
  mimeType: string;

  @Prop({ required: true })
  size: number;

  @Prop({ required: true })
  urlPath: string;
}

export const LessonAttachmentSchema =
  SchemaFactory.createForClass(LessonAttachment);

@Schema({ timestamps: true })
export class Lesson {
  @Prop({ required: true, type: Types.ObjectId, ref: 'Subject' })
  subjectId: Types.ObjectId;

  /** Enseignant créateur (JWT admin / teacher). */
  @Prop({ type: Types.ObjectId, ref: 'User' })
  teacherId?: Types.ObjectId;

  /** Optionnel : leçon rattachée à une classe (Tunisie / suivi par groupe). */
  @Prop({ type: Types.ObjectId, ref: 'Class' })
  classId?: Types.ObjectId;

  @Prop({ required: true })
  title: string;

  @Prop()
  description?: string;

  @Prop()
  content?: string;

  @Prop()
  order?: number;

  @Prop()
  level?: string;

  @Prop()
  language?: string;

  @Prop({ default: true })
  isActive: boolean;

  @Prop({ type: [LessonAttachmentSchema], default: [] })
  attachments: LessonAttachment[];
}

export const LessonSchema = SchemaFactory.createForClass(Lesson);

// Unicité par matière + classe (nullable) + titre
LessonSchema.index({ subjectId: 1, classId: 1, title: 1 }, { unique: true });
