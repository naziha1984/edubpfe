import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type LessonDocument = Lesson &
  Document & {
    createdAt: Date;
    updatedAt: Date;
  };

@Schema({ timestamps: true })
export class Lesson {
  @Prop({ required: true, type: Types.ObjectId, ref: 'Subject' })
  subjectId: Types.ObjectId;

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
}

export const LessonSchema = SchemaFactory.createForClass(Lesson);

// 确保同一科目内标题唯一（复合唯一索引）
LessonSchema.index({ subjectId: 1, title: 1 }, { unique: true });
