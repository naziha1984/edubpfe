import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document, Types } from "mongoose";

export type KidTeacherSelectionDocument = KidTeacherSelection &
  Document & {
    createdAt: Date;
    updatedAt: Date;
  };

@Schema({ timestamps: true })
export class KidTeacherSelection {
  @Prop({ required: true, type: Types.ObjectId, ref: "User" })
  parentId: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: "Kid" })
  kidId: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: "User" })
  teacherId: Types.ObjectId;

  @Prop({ required: true, default: Date.now })
  assignedAt: Date;
}

export const KidTeacherSelectionSchema =
  SchemaFactory.createForClass(KidTeacherSelection);

KidTeacherSelectionSchema.index({ kidId: 1 }, { unique: true });
KidTeacherSelectionSchema.index({ parentId: 1, teacherId: 1 });
