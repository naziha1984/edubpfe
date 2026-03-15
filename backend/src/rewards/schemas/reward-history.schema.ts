import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type RewardHistoryDocument = RewardHistory &
  Document & {
    createdAt: Date;
    updatedAt: Date;
  };

@Schema({ timestamps: true })
export class RewardHistory {
  @Prop({ required: true, type: Types.ObjectId, ref: 'Kid' })
  kidId: Types.ObjectId;

  @Prop({ required: true })
  xpEarned: number;

  @Prop()
  source: string; // 'quiz', 'streak', 'badge'

  @Prop()
  sourceId?: string; // ID of the source (quiz session, etc.)

  @Prop()
  description?: string;
}

export const RewardHistorySchema = SchemaFactory.createForClass(RewardHistory);

// 索引用于查询历史记录
RewardHistorySchema.index({ kidId: 1, createdAt: -1 });
