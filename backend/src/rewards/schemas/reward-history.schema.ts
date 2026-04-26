import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document, Types } from "mongoose";

export type RewardHistoryDocument = RewardHistory &
  Document & {
    createdAt: Date;
    updatedAt: Date;
  };

@Schema({ timestamps: true })
export class RewardHistory {
  @Prop({ required: true, type: Types.ObjectId, ref: "Kid" })
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

// 幂等：同一 kid、同一事件 source、同一 sourceId 只允许写入一条记录
// sparse: 只有 sourceId 存在时才参与唯一性约束
RewardHistorySchema.index(
  { kidId: 1, source: 1, sourceId: 1 },
  { unique: true, sparse: true },
);
