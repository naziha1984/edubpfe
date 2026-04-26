import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document, Types } from "mongoose";

export type StudentNoteDocument = StudentNote &
  Document & {
    createdAt: Date;
    updatedAt: Date;
  };

@Schema({ timestamps: true })
export class StudentNote {
  @Prop({ required: true, type: Types.ObjectId, ref: "Kid", index: true })
  kidId: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: "User", index: true })
  teacherId: Types.ObjectId;

  @Prop({ trim: true, maxlength: 1200 })
  behavior?: string;

  @Prop({ trim: true, maxlength: 1200 })
  participation?: string;

  @Prop({ trim: true, maxlength: 1200 })
  homeworkQuality?: string;

  @Prop({ trim: true, maxlength: 1200 })
  comprehension?: string;

  @Prop({ trim: true, maxlength: 1800 })
  recommendations?: string;
}

export const StudentNoteSchema = SchemaFactory.createForClass(StudentNote);

StudentNoteSchema.index({ kidId: 1, createdAt: -1 });
StudentNoteSchema.index({ teacherId: 1, kidId: 1, createdAt: -1 });
