import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document, Types } from "mongoose";

export type ClassDocument = Class &
  Document & {
    createdAt: Date;
    updatedAt: Date;
  };

@Schema({ timestamps: true })
export class Class {
  @Prop({ required: true, type: Types.ObjectId, ref: "User" })
  teacherId: Types.ObjectId;

  @Prop({ required: true })
  name: string;

  @Prop()
  description?: string;

  @Prop({ required: true, unique: true, index: true })
  classCode: string;

  @Prop({ default: true })
  isActive: boolean;
}

export const ClassSchema = SchemaFactory.createForClass(Class);
// Index créé par @Prop({ unique: true, index: true }) sur classCode
