import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type ChatMessageDocument = ChatMessage &
  Document & {
    createdAt: Date;
    updatedAt: Date;
  };

export enum MessageRole {
  USER = 'user',
  ASSISTANT = 'assistant',
  SYSTEM = 'system',
}

@Schema({ timestamps: true })
export class ChatMessage {
  @Prop({ required: true, type: Types.ObjectId, ref: 'ChatSession' })
  sessionId: Types.ObjectId;

  @Prop({ required: true, enum: MessageRole })
  role: MessageRole;

  @Prop({ required: true })
  content: string;

  @Prop()
  language?: string; // 'ar', 'fr', 'en'

  @Prop({ default: false })
  isFiltered: boolean; // 是否被安全过滤器拦截

  @Prop()
  filterReason?: string; // 过滤原因
}

export const ChatMessageSchema = SchemaFactory.createForClass(ChatMessage);

// 索引用于查询
ChatMessageSchema.index({ sessionId: 1, createdAt: 1 });
