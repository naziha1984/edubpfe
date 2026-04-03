import { Injectable } from '@nestjs/common';
import { ConfigService as NestConfigService } from '@nestjs/config';

@Injectable()
export class ConfigService {
  constructor(private configService: NestConfigService) {}

  get mongodbUri(): string {
    return this.configService.get<string>(
      'MONGODB_URI',
      'mongodb://localhost:27017/edubridge',
    );
  }

  get jwtSecret(): string {
    return this.configService.get<string>('JWT_SECRET', 'default-secret-key');
  }

  get port(): number {
    return this.configService.get<number>('PORT', 3000);
  }

  get nodeEnv(): string {
    return this.configService.get<string>('NODE_ENV', 'development');
  }

  get isDevelopment(): boolean {
    return this.nodeEnv === 'development';
  }

  get isProduction(): boolean {
    return this.nodeEnv === 'production';
  }
}
