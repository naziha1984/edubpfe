import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document, Types } from "mongoose";

export type StudentProgressEntryDocument = StudentProgressEntry &
  Document & {
    createdAt: Date;
    updatedAt: Date;
  };

@Schema({ timestamps: true })
export class StudentProgressEntry {
  @Prop({ required: true, type: Types.ObjectId, ref: "Kid", index: true })
  kidId: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: "User", index: true })
  teacherId: Types.ObjectId;

  @Prop({ required: true, min: 0, max: 100 })
  progressPercent: number;

  @Prop({ min: 0, max: 100 })
  comprehensionScore?: number;

  @Prop({ min: 0, max: 100 })
  homeworkScore?: number;

  @Prop({ min: 0, max: 100 })
  participationScore?: number;

  @Prop({ trim: true, maxlength: 200 })
  title?: string;

  @Prop({ trim: true, maxlength: 1600 })
  note?: string;
}

export const StudentProgressEntrySchema =
  SchemaFactory.createForClass(StudentProgressEntry);

StudentProgressEntrySchema.index({ kidId: 1, createdAt: -1 });
StudentProgressEntrySchema.index({ teacherId: 1, kidId: 1, createdAt: -1 });
