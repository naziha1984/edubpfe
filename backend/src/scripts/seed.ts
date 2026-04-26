import { NestFactory } from "@nestjs/core";
import { getModelToken } from "@nestjs/mongoose";
import { Model, Types } from "mongoose";
import { AppModule } from "../app.module";
import { UsersService } from "../users/users.service";
import { UserRole } from "../users/schemas/user.schema";
import { Logger } from "@nestjs/common";
import { Lesson } from "../subjects/schemas/lesson.schema";
import { QuizQuestion } from "../quiz/schemas/quiz-question.schema";

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const logger = new Logger("Seed");
  const usersService = app.get(UsersService);
  const lessonModel = app.get<Model<Lesson>>(getModelToken(Lesson.name));
  const quizQuestionModel = app.get<Model<QuizQuestion>>(
    getModelToken(QuizQuestion.name),
  );

  try {
    // Toujours aligner les comptes de seed (utile en dev si mot de passe changé)
    await usersService.upsertByEmail(
      "admin@edubridge.com",
      "admin123",
      "Admin",
      "User",
      UserRole.ADMIN,
    );
    logger.log("✅ ADMIN prêt: admin@edubridge.com / admin123");

    await usersService.upsertByEmail(
      "teacher@edubridge.com",
      "teacher123",
      "Teacher",
      "User",
      UserRole.TEACHER,
    );
    logger.log("✅ TEACHER prêt: teacher@edubridge.com / teacher123");

    const firstLesson = await lessonModel
      .findOne()
      .sort({ createdAt: 1 })
      .exec();
    if (firstLesson) {
      const lid = firstLesson._id as Types.ObjectId;
      const existing = await quizQuestionModel.countDocuments({
        lessonId: lid,
      });
      if (existing === 0) {
        await quizQuestionModel.insertMany([
          {
            lessonId: lid,
            difficulty: "easy",
            question: "What is 2 + 2?",
            options: ["3", "4", "5", "6"],
            correctAnswer: 1,
            isActive: true,
          },
          {
            lessonId: lid,
            difficulty: "medium",
            question: "What is the capital of France?",
            options: ["London", "Berlin", "Paris", "Madrid"],
            correctAnswer: 2,
            isActive: true,
          },
        ]);
        logger.log(
          `✅ Quiz: 2 questions ajoutées pour la leçon "${firstLesson.title}" (${lid})`,
        );
      } else {
        logger.log("ℹ️ Quiz: questions déjà présentes pour la première leçon");
      }
    } else {
      logger.log(
        "ℹ️ Aucune leçon en base : crée une matière + leçon puis relance le seed pour les questions quiz",
      );
    }

    logger.log("🎉 Seed completed successfully!");
  } catch (error) {
    logger.error("❌ Seed failed:", error);
  } finally {
    await app.close();
  }
}

bootstrap();
