import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type KidDocument = Kid &
  Document & {
    createdAt: Date;
    updatedAt: Date;
  };

@Schema({ timestamps: true })
export class Kid {
  @Prop({ required: true, type: Types.ObjectId, ref: 'User' })
  parentId: Types.ObjectId;

  @Prop({ required: true })
  firstName: string;

  @Prop({ required: true })
  lastName: string;

  @Prop()
  dateOfBirth?: Date;

  @Prop()
  grade?: string;

  @Prop()
  school?: string;

  @Prop({ default: true })
  isActive: boolean;

  @Prop()
  hashedPin?: string;

  @Prop()
  pinLockedUntil?: Date;

  @Prop({ default: 0 })
  failedPinAttempts: number;
}

export const KidSchema = SchemaFactory.createForClass(Kid);
