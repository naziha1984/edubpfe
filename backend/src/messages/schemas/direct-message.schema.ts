import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document, Types } from "mongoose";

export type DirectMessageDocument = DirectMessage &
  Document & {
    createdAt: Date;
    updatedAt: Date;
  };

@Schema({ timestamps: true })
export class DirectMessage {
  @Prop({ required: true, type: Types.ObjectId, ref: "Conversation" })
  conversationId: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: "User" })
  senderId: Types.ObjectId;

  @Prop({ required: true, type: Types.ObjectId, ref: "User" })
  receiverId: Types.ObjectId;

  @Prop({ required: true })
  message: string;

  @Prop({ default: false })
  isRead: boolean;

  @Prop()
  readAt?: Date;
}

export const DirectMessageSchema = SchemaFactory.createForClass(DirectMessage);

DirectMessageSchema.index({ conversationId: 1, createdAt: 1 });
DirectMessageSchema.index({ receiverId: 1, isRead: 1, createdAt: -1 });
