import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document, Types } from "mongoose";

export type ProgressDocument = Progress &
  Document & {
    createdAt: Date;
    updatedAt: Date;
  };

@Schema({ timestamps: true })
export class Progress {
  @Prop({ required: true, type: Types.ObjectId, ref: "Kid" })
  kidId: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: "Lesson" })
  lessonId: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: "Subject" })
  subjectId: Types.ObjectId;

  @Prop({ default: 0 })
  bestScore: number;

  @Prop({ default: 0 })
  attempts: number;

  @Prop({ default: false })
  isCompleted: boolean;

  @Prop()
  lastAttemptAt?: Date;
}

export const ProgressSchema = SchemaFactory.createForClass(Progress);

// 确保每个 kid 对每个 lesson 只有一个进度记录
ProgressSchema.index({ kidId: 1, lessonId: 1 }, { unique: true });
