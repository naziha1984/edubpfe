import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type ClassMembershipDocument = ClassMembership &
  Document & {
    createdAt: Date;
    updatedAt: Date;
  };

@Schema({ timestamps: true })
export class ClassMembership {
  @Prop({ required: true, type: Types.ObjectId, ref: 'Class' })
  classId: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: 'Kid' })
  kidId: Types.ObjectId;

  @Prop({ default: true })
  isActive: boolean;
}

export const ClassMembershipSchema =
  SchemaFactory.createForClass(ClassMembership);

// 确保每个 kid 在每个 class 中只有一个成员记录
ClassMembershipSchema.index({ classId: 1, kidId: 1 }, { unique: true });
