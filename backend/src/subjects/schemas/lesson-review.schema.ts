import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document, Types } from "mongoose";

export type LessonReviewDocument = LessonReview &
  Document & {
    createdAt: Date;
    updatedAt: Date;
  };

@Schema({ timestamps: true })
export class LessonReview {
  @Prop({ required: true, type: Types.ObjectId, ref: "Lesson" })
  lessonId: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: "User" })
  teacherId: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: "User" })
  parentId: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: "Kid" })
  kidId?: Types.ObjectId;

  @Prop({ required: true, min: 1, max: 5 })
  stars: number;

  @Prop({ default: "" })
  comment?: string;
}

export const LessonReviewSchema = SchemaFactory.createForClass(LessonReview);

// One parent can only review same lesson once.
LessonReviewSchema.index({ lessonId: 1, parentId: 1 }, { unique: true });
LessonReviewSchema.index({ teacherId: 1, createdAt: -1 });
LessonReviewSchema.index({ lessonId: 1, createdAt: -1 });
