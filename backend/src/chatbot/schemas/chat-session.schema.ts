import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document, Types } from "mongoose";

export type ChatSessionDocument = ChatSession &
  Document & {
    createdAt: Date;
    updatedAt: Date;
  };

@Schema({ timestamps: true })
export class ChatSession {
  @Prop({ required: true, type: Types.ObjectId, ref: "Kid" })
  kidId: Types.ObjectId;

  @Prop({ default: "en" })
  detectedLanguage: string; // 'ar', 'fr', 'en'

  @Prop({ default: true })
  isActive: boolean;
}

export const ChatSessionSchema = SchemaFactory.createForClass(ChatSession);

// 索引用于查询
ChatSessionSchema.index({ kidId: 1, isActive: 1, createdAt: -1 });
