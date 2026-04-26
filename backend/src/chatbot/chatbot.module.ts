import { Module } from "@nestjs/common";
import { MongooseModule } from "@nestjs/mongoose";
import { ChatbotController } from "./chatbot.controller";
import { ChatbotService } from "./chatbot.service";
import { LanguageDetectorService } from "./services/language-detector.service";
import { SafetyFilterService } from "./services/safety-filter.service";
import { ChatSession, ChatSessionSchema } from "./schemas/chat-session.schema";
import { ChatMessage, ChatMessageSchema } from "./schemas/chat-message.schema";
import { ConfigModule } from "../config/config.module";

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: ChatSession.name, schema: ChatSessionSchema },
      { name: ChatMessage.name, schema: ChatMessageSchema },
    ]),
    ConfigModule,
  ],
  controllers: [ChatbotController],
  providers: [ChatbotService, LanguageDetectorService, SafetyFilterService],
  exports: [ChatbotService],
})
export class ChatbotModule {}
