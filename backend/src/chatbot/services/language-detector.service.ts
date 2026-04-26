import { Injectable } from "@nestjs/common";

@Injectable()
export class LanguageDetectorService {
  // 简单的语言检测（基于关键词和字符）
  detectLanguage(text: string): "ar" | "fr" | "en" {
    if (!text || text.trim().length === 0) {
      return "en"; // 默认英语
    }

    const lowerText = text.toLowerCase().trim();

    // 检测阿拉伯语（包含阿拉伯字符）
    const arabicPattern = /[\u0600-\u06FF]/;
    if (arabicPattern.test(text)) {
      return "ar";
    }

    const trimmed = lowerText.trim();
    if (/^(bnj|bjr|bsr|slt|cc|cv)\b/.test(trimmed)) {
      return "fr";
    }

    // 检测法语关键词（ élève / matière 等无重音形式一并匹配）
    const frenchKeywords = [
      "bonjour",
      "salut",
      "merci",
      "oui",
      "non",
      "comment",
      "quoi",
      "pourquoi",
      "comment ça va",
      "ça va",
      "bien",
      "mal",
      "au revoir",
      "s'il vous plaît",
      "excusez-moi",
      "pardon",
      "je",
      "tu",
      "il",
      "elle",
      "nous",
      "vous",
      "ils",
      "elles",
      "être",
      "avoir",
      "faire",
      "aller",
      "veux",
      "voulez",
      "ajouter",
      "enfant",
      "enfants",
      "compte",
      "connexion",
      "inscription",
      "mot de passe",
      "enseignant",
      "professeur",
      "élève",
      "eleve",
      "cours",
      "classe",
      "matière",
      "matiere",
      "devoir",
      "quiz",
      "leçon",
      "lecon",
      "parent",
      "code pin",
      "pin",
    ];

    let frenchScore = frenchKeywords.reduce((score, keyword) => {
      return score + (lowerText.includes(keyword) ? 1 : 0);
    }, 0);

    // 检测英语关键词
    const englishKeywords = [
      "hello",
      "hi",
      "thank you",
      "thanks",
      "yes",
      "no",
      "how",
      "what",
      "why",
      "how are you",
      "good",
      "bad",
      "goodbye",
      "please",
      "excuse me",
      "sorry",
      "i",
      "you",
      "he",
      "she",
      "we",
      "they",
      "am",
      "is",
      "are",
      "have",
      "has",
      "do",
      "does",
      "go",
      "went",
    ];

    const englishScore = englishKeywords.reduce((score, keyword) => {
      return score + (lowerText.includes(keyword) ? 1 : 0);
    }, 0);

    if (/[àâäéèêëïîôùûçœæ]/i.test(text)) {
      frenchScore += 2;
    }

    if (frenchScore > englishScore) {
      return "fr";
    }
    if (englishScore > frenchScore) {
      return "en";
    }

    return "en";
  }

  // 获取语言名称
  getLanguageName(lang: "ar" | "fr" | "en"): string {
    const names = {
      ar: "Arabic",
      fr: "French",
      en: "English",
    };
    return names[lang];
  }
}
