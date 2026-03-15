import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type LiveSessionDocument = LiveSession &
  Document & {
    createdAt: Date;
    updatedAt: Date;
  };

export enum LiveSessionStatus {
  SCHEDULED = 'SCHEDULED',
  LIVE = 'LIVE',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
}

@Schema({ timestamps: true })
export class LiveSession {
  @Prop({ required: true, type: Types.ObjectId, ref: 'Class' })
  classId: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: 'User' })
  teacherId: Types.ObjectId;

  @Prop({ required: true })
  title: string;

  @Prop()
  description?: string;

  @Prop({ required: true, type: Date })
  scheduledAt: Date;

  @Prop({ required: true })
  meetingUrl: string;

  @Prop({ default: LiveSessionStatus.SCHEDULED, enum: LiveSessionStatus })
  status: LiveSessionStatus;

  @Prop({ default: true })
  isActive: boolean;
}

export const LiveSessionSchema = SchemaFactory.createForClass(LiveSession);

// Indexes pour les requêtes
LiveSessionSchema.index({ classId: 1, scheduledAt: 1 });
LiveSessionSchema.index({ teacherId: 1 });
LiveSessionSchema.index({ status: 1 });
