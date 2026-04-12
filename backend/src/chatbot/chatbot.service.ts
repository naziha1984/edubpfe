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
      'kid',
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
      'user',
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
    sessionId: string | undefined,
    audience: 'kid' | 'user',
  ): Promise<string> {
    if (this.USE_AI) {
      if (this.OPENAI_API_KEY) {
        return sessionId
          ? this.generateOpenAIResponse(
              message,
              language,
              sessionId,
              audience,
            )
          : this.generateOpenAIResponseStateless(message, language, audience);
      }
      if (this.GEMINI_API_KEY) {
        return sessionId
          ? this.generateGeminiResponse(message, language, sessionId, audience)
          : this.generateGeminiResponseStateless(message, language, audience);
      }
    }

    return this.generateSimpleResponse(message, language, audience);
  }

  private async generateOpenAIResponse(
    message: string,
    language: 'ar' | 'fr' | 'en',
    sessionId: string,
    audience: 'kid' | 'user',
  ): Promise<string> {
    try {
      // 获取历史消息
      const history = await this.getHistory(sessionId);

      // 构建提示
      const systemPrompt = this.getSystemPrompt(language, audience);
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
            max_tokens: audience === 'user' ? 400 : 200,
          }),
        },
      );

      if (!response.ok) {
        throw new Error(`OpenAI API error: ${response.statusText}`);
      }

      const data = await response.json();
      return (
        data.choices[0]?.message?.content ||
        this.generateSimpleResponse(message, language, audience)
      );
    } catch (error) {
      console.error('OpenAI API error:', error);
      return this.generateSimpleResponse(message, language, audience);
    }
  }

  private async generateGeminiResponse(
    message: string,
    language: 'ar' | 'fr' | 'en',
    sessionId: string,
    audience: 'kid' | 'user',
  ): Promise<string> {
    try {
      // 获取历史消息
      const history = await this.getHistory(sessionId);

      // 构建提示
      const systemPrompt = this.getSystemPrompt(language, audience);
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
        this.generateSimpleResponse(message, language, audience)
      );
    } catch (error) {
      console.error('Gemini API error:', error);
      return this.generateSimpleResponse(message, language, audience);
    }
  }

  private async generateOpenAIResponseStateless(
    message: string,
    language: 'ar' | 'fr' | 'en',
    audience: 'kid' | 'user',
  ): Promise<string> {
    try {
      const systemPrompt = this.getSystemPrompt(language, audience);
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
          max_tokens: audience === 'user' ? 400 : 200,
        }),
      });
      if (!response.ok) {
        throw new Error(`OpenAI API error: ${response.statusText}`);
      }
      const data = await response.json();
      return (
        data.choices?.[0]?.message?.content ||
        this.generateSimpleResponse(message, language, audience)
      );
    } catch (error) {
      console.error('OpenAI API error:', error);
      return this.generateSimpleResponse(message, language, audience);
    }
  }

  private async generateGeminiResponseStateless(
    message: string,
    language: 'ar' | 'fr' | 'en',
    audience: 'kid' | 'user',
  ): Promise<string> {
    try {
      const systemPrompt = this.getSystemPrompt(language, audience);
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
        this.generateSimpleResponse(message, language, audience)
      );
    } catch (error) {
      console.error('Gemini API error:', error);
      return this.generateSimpleResponse(message, language, audience);
    }
  }

  /** Réponses guidées sur l'app (sans IA ou en complément). */
  private tryEduBridgeFaq(
    message: string,
    language: 'ar' | 'fr' | 'en',
  ): string | null {
    const m = message
      .toLowerCase()
      .normalize('NFD')
      .replace(/\p{M}/gu, '');

    const wantsAddChild =
      (m.includes('enfant') || m.includes('child') || m.includes('kid')) &&
      (m.includes('ajout') ||
        m.includes('add') ||
        m.includes('creer') ||
        m.includes('nouveau') ||
        m.includes('new') ||
        m.includes('veux') ||
        m.includes('voulez') ||
        m.includes('want'));

    if (wantsAddChild) {
      const t = {
        fr: "Pour ajouter un enfant dans EduBridge : connecte-toi avec un compte parent ou enseignant. Depuis l'accueil ou le tableau de bord, ouvre la section **Enfants** (liste / gestion des enfants), puis crée un profil enfant et définis son **code PIN** — il servira à ouvrir la session enfant sur l'appareil. Si tu ne vois pas le menu, vérifie que tu es bien connecté avec le bon rôle.",
        en: 'To add a child in EduBridge: sign in as a **parent** or **teacher**. From the home or dashboard, open **Kids** (children list / management), create a child profile, and set a **PIN** — the child uses it to start the kid session on the device. If you do not see the option, confirm you are logged in with the correct role.',
        ar: 'لإضافة طفل في EduBridge: سجّل الدخول كولي أمر أو معلم. من الشاشة الرئيسية أو لوحة التحكم، افتح قسم **الأطفال**، أنشئ ملف الطفل وعيّن **رمز PIN** ليبدأ الطفل جلسة الطفل على الجهاز. إذا لم يظهر القسم، تأكد من الدخول بالدور الصحيح.',
      };
      return t[language];
    }

    if (
      m.includes('connexion') ||
      m.includes('connecter') ||
      m.includes('login') ||
      m.includes('sign in') ||
      m.includes('mot de passe') ||
      m.includes('password') ||
      m.includes('compte') ||
      m.includes('account')
    ) {
      const t = {
        fr: "Pour te connecter : sur l'écran d'accueil, choisis **Connexion**, entre ton e-mail et ton mot de passe. Si tu as oublié le mot de passe, utilise la réinitialisation côté compte (selon ce que propose ton écran). Les **enseignants** et **parents** utilisent la même entrée de connexion avec des rôles différents après le chargement du profil.",
        en: 'To sign in: on the welcome screen choose **Login**, enter your email and password. Teachers and parents use the same login entry; your role is determined after your profile loads.',
        ar: 'لتسجيل الدخول: من شاشة الترحيب اختر **تسجيل الدخول** وأدخل البريد وكلمة المرور. يستخدم المعلمون وأولياء الأمور نفس نقطة الدخول.',
      };
      return t[language];
    }

    if (
      m.includes('enseignant') ||
      m.includes('teacher') ||
      m.includes('classe') ||
      m.includes('class') ||
      m.includes('eleve') ||
      m.includes('élève') ||
      m.includes('student')
    ) {
      const t = {
        fr: "Côté **enseignant** : après connexion, ouvre le **tableau de bord enseignant**. Tu y gères tes **classes**, vois les **élèves**, les **matières / leçons**, **quiz**, **devoirs** et **sessions en direct** selon les menus disponibles. Utilise **Notifications** pour les alertes récentes.",
        en: 'As a **teacher**: after sign-in, open the **teacher dashboard**. From there you can manage **classes**, **students**, **subjects / lessons**, **quizzes**, **assignments**, and **live sessions** where available. Check **Notifications** for updates.',
        ar: 'كمعلم: بعد تسجيل الدخول افتح **لوحة المعلم** لإدارة **الفصول** و**التلاميذ** و**الدروس** و**الاختبارات** و**الواجبات** و**الجلسات المباشرة** حسب القوائم المتوفرة.',
      };
      return t[language];
    }

    if (
      m.includes('quiz') ||
      m.includes('devoir') ||
      m.includes('assignment') ||
      m.includes('lecon') ||
      m.includes('leçon') ||
      m.includes('lesson')
    ) {
      const t = {
        fr: "Les **quiz** et **leçons** se trouvent dans les écrans **Matières / Leçons** (élève ou enfant avec PIN) ou dans le parcours prévu par l'enseignant. Les **devoirs** (assignments) ont souvent une section dédiée dans l'espace enfant ou enseignant.",
        en: '**Quizzes** and **lessons** are under **Subjects / Lessons** (student or kid with PIN) or as organized by the teacher. **Assignments** usually have a dedicated area in the kid or teacher experience.',
        ar: 'تجد **الاختبارات** و**الدروس** ضمن **المواد / الدروس** (للتلميذ أو الطفل برمز PIN) أو حسب تنظيم المعلم. **الواجبات** لها غالباً قسم مخصص.',
      };
      return t[language];
    }

    if (
      m.includes('aide') ||
      m.includes('help') ||
      m.includes('utiliser') ||
      m.includes('fonctionne') ||
      (m.includes('comment') &&
        (m.includes('utiliser') || m.includes('marche') || m.includes('app')))
    ) {
      const t = {
        fr: "Je peux t'expliquer l'app EduBridge : **ajouter un enfant**, **connexion**, **rôle parent / enseignant**, **classes**, **quiz**, **notifications**. Pose une question précise (par exemple : « comment ajouter un enfant ? »).",
        en: 'I can help with EduBridge: **adding a child**, **sign-in**, **parent vs teacher**, **classes**, **quizzes**, **notifications**. Ask something specific (e.g. “How do I add a child?”).',
        ar: 'يمكنني المساعدة في EduBridge: **إضافة طفل**، **تسجيل الدخول**، **ولي الأمر / المعلم**، **الفصول**، **الاختبارات**، **الإشعارات**. اطرح سؤالاً محدداً.',
      };
      return t[language];
    }

    return null;
  }

  private generateSimpleResponse(
    message: string,
    language: 'ar' | 'fr' | 'en',
    _audience: 'kid' | 'user',
  ): string {
    const faq = this.tryEduBridgeFaq(message, language);
    if (faq) {
      return faq.replace(/\*\*(.+?)\*\*/g, '$1');
    }

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
      lowerMessage.includes('bnj') ||
      lowerMessage.includes('bjr') ||
      lowerMessage.includes('bsr') ||
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

  private getSystemPrompt(
    language: 'ar' | 'fr' | 'en',
    audience: 'kid' | 'user',
  ): string {
    if (audience === 'user') {
      const prompts = {
        en: 'You are EduBridge’s in-app assistant for parents and teachers. Answer in clear, practical steps. Topics: sign-in, roles, adding a child and PIN, classes, lessons, quizzes, assignments, notifications. Match the user’s language (English here). If unsure, say where to look in the app instead of inventing features.',
        fr: "Tu es l’assistant EduBridge pour parents et enseignants dans l’application. Réponds en français, avec des étapes courtes et utiles : connexion, rôles, ajout d’un enfant et code PIN, classes, leçons, quiz, devoirs, notifications. Si tu n’es pas sûr, indique où chercher dans l’app plutôt que d’inventer.",
        ar: 'أنت مساعد EduBridge داخل التطبيق لأولياء الأمور والمعلمين. أجب بالعربية بخطوات واضحة ومختصرة: تسجيل الدخول، الأدوار، إضافة طفل ورمز PIN، الفصول، الدروس، الاختبارات، الواجبات، الإشعارات. إن لم تكن متأكداً فاذكر أين يبحث المستخدم في التطبيق.',
      };
      return prompts[language];
    }
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
