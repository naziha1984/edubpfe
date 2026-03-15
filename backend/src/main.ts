import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';
import { ConfigService } from './config/config.service';
import { LoggerService } from './common/logger/logger.service';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    logger: ['error', 'warn', 'log', 'debug', 'verbose'],
  });

  const configService = app.get(ConfigService);
  const logger = app.get(LoggerService);
  logger.setContext('Bootstrap');

  // Enable CORS
  app.enableCors();

  // Route racine pour éviter l'erreur 404
  const expressApp = app.getHttpAdapter().getInstance();
  expressApp.get('/', (req, res) => {
    res.json({
      message: 'EduBridge API',
      version: '1.0.0',
      api: '/api',
      health: '/api/health',
    });
  });

  // Global prefix
  app.setGlobalPrefix('api');

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // Global exception filter
  app.useGlobalFilters(new HttpExceptionFilter());

  const port = configService.port;
  await app.listen(port);

  logger.log(`🚀 EduBridge Backend is running on: http://localhost:${port}`);
  logger.log(`📊 Environment: ${configService.nodeEnv}`);
  logger.log(`🔗 MongoDB URI: ${configService.mongodbUri}`);
}
bootstrap();
