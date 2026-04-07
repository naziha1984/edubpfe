import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import {
  ChatSession,
  ChatSessionDocument,
} from './schemas/chat-session.schema';
import {
  ChatMessage,
  ChatMessageDocument,
  MessageRole,
} from './schemas/chat-message.schema';
import { LanguageDetectorService } from './services/language-detector.service';
import { SafetyFilterService } from './services/safety-filter.service';
import { ConfigService } from '../config/config.service';

@Injectable()
export class ChatbotService {
  private readonly OPENAI_API_KEY: string | undefined;
  private readonly GEMINI_API_KEY: string | undefined;
  private readonly USE_AI: boolean;

  constructor(
    @InjectModel(ChatSession.name)
    private chatSessionModel: Model<ChatSessionDocument>,
    @InjectModel(ChatMessage.name)
    private chatMessageModel: Model<ChatMessageDocument>,
    private languageDetector: LanguageDetectorService,
    private safetyFilter: SafetyFilterService,
    private configService: ConfigService,
  ) {
    // 从环境变量获取 API 密钥
    this.OPENAI_API_KEY = process.env.OPENAI_API_KEY;
    this.GEMINI_API_KEY = process.env.GEMINI_API_KEY;
    this.USE_AI = !!(this.OPENAI_API_KEY || this.GEMINI_API_KEY);
  }

  async getOrCreateSession(kidId: string): Promise<ChatSessionDocument> {
    let session = await this.chatSessionModel
      .findOne({
        kidId: new Types.ObjectId(kidId),
        isActive: true,
      })
      .sort({ createdAt: -1 })
      .exec();

    if (!session) {
      session = new this.chatSessionModel({
        kidId: new Types.ObjectId(kidId),
        detectedLanguage: 'en',
        isActive: true,
      });
      await session.save();
    }

    return session;
  }

  async sendMessage(
    kidId: string,
    message: string,
  ): Promise<{
    response: string;
    sessionId: string;
    language: string;
    isFiltered: boolean;
  }> {
    if (!message || message.trim().length === 0) {
      throw new BadRequestException('Message cannot be empty');
    }

    // 获取或创建会话
    const session = await this.getOrCreateSession(kidId);

    // 检测语言
    const detectedLanguage = this.languageDetector.detectLanguage(message);

    // 更新会话语言（如果改变）
    if (session.detectedLanguage !== detectedLanguage) {
      session.detectedLanguage = detectedLanguage;
      await session.save();
    }

    // 安全过滤
    const safetyCheck = this.safetyFilter.checkSafety(
      message,
      detectedLanguage,
    );
    if (!safetyCheck.isSafe) {
      // 保存被过滤的消息
      const filteredMessage = new this.chatMessageModel({
        sessionId: session._id,
        role: MessageRole.USER,
        content: message,
        language: detectedLanguage,
        isFiltered: true,
        filterReason: safetyCheck.reason,
      });
      await filteredMessage.save();

      // 返回安全响应
      const safetyResponse =
        this.safetyFilter.getSafetyResponse(detectedLanguage);
      const responseMessage = new this.chatMessageModel({
        sessionId: session._id,
        role: MessageRole.ASSISTANT,
        content: safetyResponse,
        language: detectedLanguage,
      });
      await responseMessage.save();

      return {
        response: safetyResponse,
        sessionId: session._id.toString(),
        language: detectedLanguage,
        isFiltered: true,
      };
    }

    // 保存用户消息
    const userMessage = new this.chatMessageModel({
      sessionId: session._id,
      role: MessageRole.USER,
      content: message,
      language: detectedLanguage,
    });
    await userMessage.save();

    // 生成 AI 响应
    const aiResponse = await this.generateResponse(
      message,
      detectedLanguage,
      session._id.toString(),
    );

    // 保存 AI 响应
    const assistantMessage = new this.chatMessageModel({
      sessionId: session._id,
      role: MessageRole.ASSISTANT,
      content: aiResponse,
      language: detectedLanguage,
    });
    await assistantMessage.save();

    return {
      response: aiResponse,
      sessionId: session._id.toString(),
      language: detectedLanguage,
      isFiltered: false,
    };
  }

  async sendMessageForUser(
    message: string,
  ): Promise<{
    response: string;
    language: string;
    isFiltered: boolean;
  }> {
    if (!message || message.trim().length === 0) {
      throw new BadRequestException('Message cannot be empty');
    }

    const detectedLanguage = this.languageDetector.detectLanguage(message);
    const safetyCheck = this.safetyFilter.checkSafety(message, detectedLanguage);
    if (!safetyCheck.isSafe) {
      const safetyResponse = this.safetyFilter.getSafetyResponse(detectedLanguage);
      return {
        response: safetyResponse,
        language: detectedLanguage,
        isFiltered: true,
      };
    }

    const aiResponse = await this.generateResponse(
      message,
      detectedLanguage,
      undefined,
    );
    return {
      response: aiResponse,
      language: detectedLanguage,
      isFiltered: false,
    };
  }

  private async generateResponse(
    message: string,
    language: 'ar' | 'fr' | 'en',
    sessionId?: string,
  ): Promise<string> {
    // 如果配置了 AI，使用 AI 生成响应
    if (this.USE_AI) {
      if (this.OPENAI_API_KEY) {
        return sessionId
          ? this.generateOpenAIResponse(message, language, sessionId)
          : this.generateOpenAIResponseStateless(message, language);
      } else if (this.GEMINI_API_KEY) {
        return sessionId
          ? this.generateGeminiResponse(message, language, sessionId)
          : this.generateGeminiResponseStateless(message, language);
      }
    }

    // 否则使用简单的规则响应
    return this.generateSimpleResponse(message, language);
  }

  private async generateOpenAIResponse(
    message: string,
    language: 'ar' | 'fr' | 'en',
    sessionId: string,
  ): Promise<string> {
    try {
      // 获取历史消息
      const history = await this.getHistory(sessionId);

      // 构建提示
      const systemPrompt = this.getSystemPrompt(language);
      const messages = [
        { role: 'system', content: systemPrompt },
        ...history.map((msg) => ({
          role: msg.role,
          content: msg.content,
        })),
        { role: 'user', content: message },
      ];

      // 调用 OpenAI API
      const response = await fetch(
        'https://api.openai.com/v1/chat/completions',
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${this.OPENAI_API_KEY}`,
          },
          body: JSON.stringify({
            model: 'gpt-3.5-turbo',
            messages: messages,
            temperature: 0.7,
            max_tokens: 200,
          }),
        },
      );

      if (!response.ok) {
        throw new Error(`OpenAI API error: ${response.statusText}`);
      }

      const data = await response.json();
      return (
        data.choices[0]?.message?.content ||
        this.generateSimpleResponse(message, language)
      );
    } catch (error) {
      console.error('OpenAI API error:', error);
      return this.generateSimpleResponse(message, language);
    }
  }

  private async generateGeminiResponse(
    message: string,
    language: 'ar' | 'fr' | 'en',
    sessionId: string,
  ): Promise<string> {
    try {
      // 获取历史消息
      const history = await this.getHistory(sessionId);

      // 构建提示
      const systemPrompt = this.getSystemPrompt(language);
      const conversation = history
        .map(
          (msg) =>
            `${msg.role === 'user' ? 'User' : 'Assistant'}: ${msg.content}`,
        )
        .join('\n');

      const fullPrompt = `${systemPrompt}\n\n${conversation}\nUser: ${message}\nAssistant:`;

      // 调用 Gemini API
      const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${this.GEMINI_API_KEY}`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            contents: [
              {
                parts: [{ text: fullPrompt }],
              },
            ],
          }),
        },
      );

      if (!response.ok) {
        throw new Error(`Gemini API error: ${response.statusText}`);
      }

      const data = await response.json();
      return (
        data.candidates[0]?.content?.parts[0]?.text ||
        this.generateSimpleResponse(message, language)
      );
    } catch (error) {
      console.error('Gemini API error:', error);
      return this.generateSimpleResponse(message, language);
    }
  }

  private async generateOpenAIResponseStateless(
    message: string,
    language: 'ar' | 'fr' | 'en',
  ): Promise<string> {
    try {
      const systemPrompt = this.getSystemPrompt(language);
      const response = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${this.OPENAI_API_KEY}`,
        },
        body: JSON.stringify({
          model: 'gpt-3.5-turbo',
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: message },
          ],
          temperature: 0.7,
          max_tokens: 200,
        }),
      });
      if (!response.ok) {
        throw new Error(`OpenAI API error: ${response.statusText}`);
      }
      const data = await response.json();
      return (
        data.choices?.[0]?.message?.content ||
        this.generateSimpleResponse(message, language)
      );
    } catch (error) {
      console.error('OpenAI API error:', error);
      return this.generateSimpleResponse(message, language);
    }
  }

  private async generateGeminiResponseStateless(
    message: string,
    language: 'ar' | 'fr' | 'en',
  ): Promise<string> {
    try {
      const systemPrompt = this.getSystemPrompt(language);
      const fullPrompt = `${systemPrompt}\n\nUser: ${message}\nAssistant:`;

      const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${this.GEMINI_API_KEY}`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            contents: [{ parts: [{ text: fullPrompt }] }],
          }),
        },
      );

      if (!response.ok) {
        throw new Error(`Gemini API error: ${response.statusText}`);
      }

      const data = await response.json();
      return (
        data.candidates?.[0]?.content?.parts?.[0]?.text ||
        this.generateSimpleResponse(message, language)
      );
    } catch (error) {
      console.error('Gemini API error:', error);
      return this.generateSimpleResponse(message, language);
    }
  }

  private generateSimpleResponse(
    message: string,
    language: 'ar' | 'fr' | 'en',
  ): string {
    const lowerMessage = message.toLowerCase().trim();

    // 简单的规则响应
    const responses = {
      en: {
        greeting: ['Hello!', 'Hi there!', 'Hey! How can I help you?'],
        question: [
          "That's an interesting question!",
          "I'm here to help!",
          'Let me think about that...',
        ],
        default: ['I understand!', "That's interesting!", 'Tell me more!'],
      },
      fr: {
        greeting: [
          'Bonjour!',
          'Salut!',
          'Bonjour! Comment puis-je vous aider?',
        ],
        question: [
          "C'est une question intéressante!",
          'Je suis là pour aider!',
          'Laissez-moi réfléchir...',
        ],
        default: ['Je comprends!', "C'est intéressant!", 'Dites-moi en plus!'],
      },
      ar: {
        greeting: ['مرحبا!', 'أهلا!', 'مرحبا! كيف يمكنني مساعدتك?'],
        question: [
          'هذا سؤال مثير للاهتمام!',
          'أنا هنا للمساعدة!',
          'دعني أفكر في ذلك...',
        ],
        default: ['أفهم!', 'هذا مثير للاهتمام!', 'أخبرني المزيد!'],
      },
    };

    const langResponses = responses[language];

    // 检测问候
    if (
      lowerMessage.includes('hello') ||
      lowerMessage.includes('hi') ||
      lowerMessage.includes('bonjour') ||
      lowerMessage.includes('salut') ||
      lowerMessage.includes('مرحبا') ||
      lowerMessage.includes('أهلا')
    ) {
      return langResponses.greeting[
        Math.floor(Math.random() * langResponses.greeting.length)
      ];
    }

    // 检测问题
    if (
      lowerMessage.includes('?') ||
      lowerMessage.includes('؟') ||
      lowerMessage.includes('what') ||
      lowerMessage.includes('how') ||
      lowerMessage.includes('why') ||
      lowerMessage.includes('quoi') ||
      lowerMessage.includes('comment') ||
      lowerMessage.includes('pourquoi') ||
      lowerMessage.includes('ماذا') ||
      lowerMessage.includes('كيف') ||
      lowerMessage.includes('لماذا')
    ) {
      return langResponses.question[
        Math.floor(Math.random() * langResponses.question.length)
      ];
    }

    // 默认响应
    return langResponses.default[
      Math.floor(Math.random() * langResponses.default.length)
    ];
  }

  private getSystemPrompt(language: 'ar' | 'fr' | 'en'): string {
    const prompts = {
      en: 'You are a friendly and educational chatbot for children. Keep responses simple, positive, and age-appropriate. Always respond in English.',
      fr: "Vous êtes un chatbot amical et éducatif pour les enfants. Gardez les réponses simples, positives et adaptées à l'âge. Répondez toujours en français.",
      ar: 'أنت روبوت محادثة ودود وتعليمي للأطفال. حافظ على الردود بسيطة وإيجابية ومناسبة للعمر. ارد دائما بالعربية.',
    };
    return prompts[language];
  }

  async getHistory(
    sessionId: string,
    kidId?: string,
    limit: number = 20,
  ): Promise<ChatMessageDocument[]> {
    // Sécurité: si le kidId est fourni, on vérifie que la session appartient bien au kid.
    if (kidId) {
      const session = await this.chatSessionModel
        .findOne({
          _id: new Types.ObjectId(sessionId),
          kidId: new Types.ObjectId(kidId),
        })
        .exec();
      if (!session) {
        throw new NotFoundException('Chat session not found');
      }
    }

    return this.chatMessageModel
      .find({ sessionId: new Types.ObjectId(sessionId) })
      .sort({ createdAt: 1 }) // 按时间正序排列（最早的在前）
      .limit(limit)
      .exec();
  }

  async getSessions(kidId: string): Promise<ChatSessionDocument[]> {
    return this.chatSessionModel
      .find({ kidId: new Types.ObjectId(kidId) })
      .sort({ createdAt: -1 })
      .exec();
  }
}
