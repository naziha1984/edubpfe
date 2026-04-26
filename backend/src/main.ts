import { NestFactory } from "@nestjs/core";
import { ValidationPipe } from "@nestjs/common";
import { NestExpressApplication } from "@nestjs/platform-express";
import { IoAdapter } from "@nestjs/platform-socket.io";
import { join } from "path";
import { AppModule } from "./app.module";
import { ConfigService } from "./config/config.service";
import { LoggerService } from "./common/logger/logger.service";
import { HttpExceptionFilter } from "./common/filters/http-exception.filter";

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    logger: ["error", "warn", "log", "debug", "verbose"],
  });

  const configService = app.get(ConfigService);
  const logger = app.get(LoggerService);
  logger.setContext("Bootstrap");

  // Enable CORS
  app.enableCors();

  app.useWebSocketAdapter(new IoAdapter(app));

  app.useStaticAssets(join(process.cwd(), "uploads"), {
    prefix: "/api/uploads/",
  });

  // Route racine pour éviter l'erreur 404
  const expressApp = app.getHttpAdapter().getInstance();

  expressApp.get("/", (req, res) => {
    res.json({
      message: "EduBridge API",
      version: "1.0.0",
      api: "/api",
      health: "/api/health",
    });
  });

  // Global prefix
  app.setGlobalPrefix("api");

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

  const basePort = Number(configService.port) || 3000;
  let boundPort: number | null = null;
  const host = "127.0.0.1";

  for (let i = 0; i < 10; i += 1) {
    const candidate = basePort + i;
    try {
      await app.listen(candidate, host);
      boundPort = candidate;
      break;
    } catch (error: any) {
      if (error?.code === "EADDRINUSE") {
        logger.warn(
          `Port ${candidate} occupé, tentative sur ${candidate + 1}...`,
        );
        continue;
      }
      throw error;
    }
  }

  if (boundPort == null) {
    throw new Error(
      `Aucun port disponible entre ${basePort} et ${basePort + 9}`,
    );
  }
  logger.log(
    `🚀 EduBridge Backend is running on: http://localhost:${boundPort}`,
  );
  logger.log(`📊 Environment: ${configService.nodeEnv}`);
  logger.log(`🔗 MongoDB URI: ${configService.mongodbUri}`);
}
bootstrap();
