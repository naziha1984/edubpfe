import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document, Types } from "mongoose";

export type RewardDocument = Reward & Document;

@Schema({ timestamps: true })
export class Reward {
  @Prop({ required: true, type: Types.ObjectId, ref: "Kid" })
  kidId: Types.ObjectId;

  @Prop({ default: 0 })
  totalXP: number;

  @Prop({ default: 0 })
  currentLevel: number;

  @Prop({ default: 0 })
  currentStreak: number;

  @Prop()
  lastStreakDate?: Date;

  @Prop({ type: [Types.ObjectId], ref: "Badge", default: [] })
  badges: Types.ObjectId[];
}

export const RewardSchema = SchemaFactory.createForClass(Reward);

// 确保每个 kid 只有一个 reward 记录
RewardSchema.index({ kidId: 1 }, { unique: true });
