import { Injectable } from '@nestjs/common';

@Injectable()
export class LanguageDetectorService {
  // 简单的语言检测（基于关键词和字符）
  detectLanguage(text: string): 'ar' | 'fr' | 'en' {
    if (!text || text.trim().length === 0) {
      return 'en'; // 默认英语
    }

    const lowerText = text.toLowerCase().trim();

    // 检测阿拉伯语（包含阿拉伯字符）
    const arabicPattern = /[\u0600-\u06FF]/;
    if (arabicPattern.test(text)) {
      return 'ar';
    }

    // 检测法语关键词
    const frenchKeywords = [
      'bonjour', 'salut', 'merci', 'oui', 'non', 'comment', 'quoi',
      'pourquoi', 'comment ça va', 'ça va', 'bien', 'mal', 'au revoir',
      's\'il vous plaît', 'excusez-moi', 'pardon', 'je', 'tu', 'il', 'elle',
      'nous', 'vous', 'ils', 'elles', 'être', 'avoir', 'faire', 'aller',
    ];

    const frenchScore = frenchKeywords.reduce((score, keyword) => {
      return score + (lowerText.includes(keyword) ? 1 : 0);
    }, 0);

    // 检测英语关键词
    const englishKeywords = [
      'hello', 'hi', 'thank you', 'thanks', 'yes', 'no', 'how', 'what',
      'why', 'how are you', 'good', 'bad', 'goodbye', 'please', 'excuse me',
      'sorry', 'i', 'you', 'he', 'she', 'we', 'they', 'am', 'is', 'are',
      'have', 'has', 'do', 'does', 'go', 'went',
    ];

    const englishScore = englishKeywords.reduce((score, keyword) => {
      return score + (lowerText.includes(keyword) ? 1 : 0);
    }, 0);

    // 如果法语关键词明显多于英语，返回法语
    if (frenchScore > englishScore && frenchScore > 2) {
      return 'fr';
    }

    // 默认返回英语
    return 'en';
  }

  // 获取语言名称
  getLanguageName(lang: 'ar' | 'fr' | 'en'): string {
    const names = {
      ar: 'Arabic',
      fr: 'French',
      en: 'English',
    };
    return names[lang];
  }
}
