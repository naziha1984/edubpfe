import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ChatbotService } from './chatbot.service';
import { KidAuthGuard } from '../kids/guards/kid-auth.guard';
import { GetKid } from '../kids/decorators/get-kid.decorator';

export class SendMessageDto {
  message: string;
}

@Controller('chatbot')
export class ChatbotController {
  constructor(private readonly chatbotService: ChatbotService) {}

  @Post('message')
  @UseGuards(KidAuthGuard)
  @HttpCode(HttpStatus.OK)
  async sendMessage(
    @Body() sendMessageDto: SendMessageDto,
    @GetKid() kid: any,
  ) {
    const result = await this.chatbotService.sendMessage(
      kid.kidId,
      sendMessageDto.message,
    );

    return {
      response: result.response,
      sessionId: result.sessionId,
      language: result.language,
      isFiltered: result.isFiltered,
    };
  }

  @Get('history/:sessionId')
  @UseGuards(KidAuthGuard)
  async getHistory(
    @Param('sessionId') sessionId: string,
    @GetKid() kid: any,
  ) {
    // 验证会话属于该 kid（通过 ChatbotService 内部验证）
    const history = await this.chatbotService.getHistory(sessionId);

    return history.map((msg) => ({
      id: msg._id.toString(),
      role: msg.role,
      content: msg.content,
      language: msg.language,
      isFiltered: msg.isFiltered,
      filterReason: msg.filterReason,
      createdAt: msg.createdAt,
    }));
  }

  @Get('sessions')
  @UseGuards(KidAuthGuard)
  async getSessions(@GetKid() kid: any) {
    const sessions = await this.chatbotService.getSessions(kid.kidId);

    return sessions.map((session) => ({
      id: session._id.toString(),
      kidId: session.kidId.toString(),
      detectedLanguage: session.detectedLanguage,
      isActive: session.isActive,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
    }));
  }
}
