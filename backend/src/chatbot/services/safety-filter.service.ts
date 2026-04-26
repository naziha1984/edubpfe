import { Injectable } from "@nestjs/common";

@Injectable()
export class SafetyFilterService {
  // 不安全的词汇列表（示例，实际应该更全面）
  private readonly unsafeWords = [
    // 英语
    "violence",
    "weapon",
    "gun",
    "knife",
    "kill",
    "hurt",
    "attack",
    "drug",
    "alcohol",
    "cigarette",
    "smoke",
    "drunk",
    "sex",
    "sexual",
    "nude",
    "naked",
    "porn",
    "hate",
    "racist",
    "discrimination",
    // 法语
    "violence",
    "arme",
    "tuer",
    "blesser",
    "attaquer",
    "drogue",
    "alcool",
    "cigarette",
    "fumer",
    "ivre",
    "sexe",
    "sexuel",
    "nu",
    "porno",
    "haine",
    "raciste",
    "discrimination",
    // 阿拉伯语（音译）
    "عنف",
    "سلاح",
    "قتل",
    "إيذاء",
    "هجوم",
    "مخدرات",
    "كحول",
    "سجائر",
    "تدخين",
    "سكران",
    "جنس",
    "جنسي",
    "عري",
    "إباحية",
    "كراهية",
    "عنصري",
    "تمييز",
  ];

  // 检查消息是否安全
  checkSafety(
    message: string,
    _language: "ar" | "fr" | "en",
  ): {
    isSafe: boolean;
    reason?: string;
  } {
    if (!message || message.trim().length === 0) {
      return { isSafe: true };
    }

    // Paramètre non utilisé pour l'instant (on garde la signature pour compatibilité).
    void _language;

    const lowerMessage = message.toLowerCase().trim();

    // 检查不安全的词汇
    for (const word of this.unsafeWords) {
      if (lowerMessage.includes(word.toLowerCase())) {
        return {
          isSafe: false,
          reason: `Message contains inappropriate content: ${word}`,
        };
      }
    }

    // 检查是否包含个人信息请求（可能不安全）
    const personalInfoPatterns = [
      /where do you live/i,
      /what is your address/i,
      /what is your phone/i,
      /what is your email/i,
      /où habites-tu/i,
      /quelle est ton adresse/i,
      /quel est ton téléphone/i,
      /quel est ton email/i,
      /أين تعيش/i,
      /ما هو عنوانك/i,
      /ما هو رقم هاتفك/i,
      /ما هو بريدك الإلكتروني/i,
    ];

    for (const pattern of personalInfoPatterns) {
      if (pattern.test(message)) {
        return {
          isSafe: false,
          reason: "Message requests personal information",
        };
      }
    }

    // 检查是否包含外部链接（可能不安全）
    const urlPattern = /https?:\/\/[^\s]+/i;
    if (urlPattern.test(message)) {
      return {
        isSafe: false,
        reason: "Message contains external links",
      };
    }

    return { isSafe: true };
  }

  // 获取安全响应消息
  getSafetyResponse(language: "ar" | "fr" | "en"): string {
    const responses = {
      en: "I'm sorry, but I can't respond to that. Let's talk about something else!",
      fr: "Je suis désolé, mais je ne peux pas répondre à cela. Parlons d'autre chose !",
      ar: "أنا آسف، لكن لا يمكنني الرد على ذلك. دعنا نتحدث عن شيء آخر!",
    };
    return responses[language];
  }
}
