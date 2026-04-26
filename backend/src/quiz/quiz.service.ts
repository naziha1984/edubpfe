import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model, Types } from "mongoose";
import {
  QuizSession,
  QuizSessionDocument,
} from "./schemas/quiz-session.schema";
import { Progress, ProgressDocument } from "./schemas/progress.schema";
import {
  QuizQuestion,
  QuizQuestionDocument,
  QuizDifficulty,
} from "./schemas/quiz-question.schema";
import { NotificationsService } from "../notifications/notifications.service";
import { NotificationType } from "../notifications/schemas/notification.schema";
import { CreateSessionDto } from "./dto/create-session.dto";
import { SubmitQuizDto } from "./dto/submit-quiz.dto";
import { CreateQuizQuestionDto } from "./dto/create-quiz-question.dto";
import { LessonsService } from "../subjects/lessons.service";
import { SubjectsService } from "../subjects/subjects.service";
import { RewardsService } from "../rewards/rewards.service";
import { UserRole } from "../users/schemas/user.schema";

@Injectable()
export class QuizService {
  constructor(
    @InjectModel(QuizSession.name)
    private quizSessionModel: Model<QuizSessionDocument>,
    @InjectModel(Progress.name)
    private progressModel: Model<ProgressDocument>,
    @InjectModel(QuizQuestion.name)
    private quizQuestionModel: Model<QuizQuestionDocument>,
    private lessonsService: LessonsService,
    private subjectsService: SubjectsService,
    private rewardsService: RewardsService,
    private notificationsService: NotificationsService,
  ) {}

  async createSession(
    createSessionDto: CreateSessionDto,
    kidIdFromToken: string,
  ) {
    // Vérification IDOR stricte : le kidId du token doit correspondre à celui de la requête
    if (createSessionDto.kidId !== kidIdFromToken) {
      throw new ForbiddenException("You can only create sessions for yourself");
    }

    // Vérifier que la leçon existe
    const lesson = await this.lessonsService.findOne(createSessionDto.lessonId);
    if (!lesson) {
      throw new NotFoundException("Lesson not found");
    }

    // Récupérer la matière depuis la leçon
    const subject = await this.subjectsService.findOne(
      lesson.subjectId.toString(),
    );
    if (!subject) {
      throw new NotFoundException("Subject not found");
    }

    // Créer ou mettre à jour la progression
    await this.progressModel.findOneAndUpdate(
      {
        kidId: new Types.ObjectId(kidIdFromToken),
        lessonId: new Types.ObjectId(createSessionDto.lessonId),
      },
      {
        kidId: new Types.ObjectId(kidIdFromToken),
        lessonId: new Types.ObjectId(createSessionDto.lessonId),
        subjectId: lesson.subjectId,
      },
      { upsert: true, new: true },
    );

    // Créer la session de quiz
    const session = new this.quizSessionModel({
      kidId: new Types.ObjectId(kidIdFromToken),
      lessonId: new Types.ObjectId(createSessionDto.lessonId),
      status: "in_progress",
      difficultyFilter: createSessionDto.difficulty,
    });

    return session.save();
  }

  async submitQuiz(
    submitQuizDto: SubmitQuizDto,
    kidIdFromToken: string,
  ): Promise<{
    score: number;
    totalQuestions: number;
    percentage: number;
    xpEarned: number;
  }> {
    // Charger la session
    const session = await this.quizSessionModel.findById(
      submitQuizDto.sessionId,
    );
    if (!session) {
      throw new NotFoundException("Quiz session not found");
    }

    // Vérification IDOR stricte : la session doit appartenir à l'enfant du token
    if (session.kidId.toString() !== kidIdFromToken) {
      throw new ForbiddenException(
        "You can only submit quizzes for your own sessions",
      );
    }

    if (session.status === "completed") {
      throw new BadRequestException("Quiz session already completed");
    }

    const qFilter: Record<string, unknown> = {
      lessonId: session.lessonId,
      isActive: true,
    };
    if (session.difficultyFilter) {
      qFilter.difficulty = session.difficultyFilter;
    }

    const questions = await this.quizQuestionModel
      .find(qFilter)
      .sort({ createdAt: 1 })
      .exec();

    if (questions.length === 0) {
      throw new BadRequestException(
        "This lesson has no quiz questions yet. Add questions in the database or use a lesson that includes a quiz.",
      );
    }

    // Calculer le score
    let correctAnswers = 0;
    const totalQuestions = questions.length;

    submitQuizDto.answers.forEach((answer) => {
      const question = questions[answer.questionIndex];
      if (question && question.correctAnswer === answer.selectedAnswer) {
        correctAnswers++;
      }
    });

    const score = correctAnswers;
    const percentage = Math.round((score / totalQuestions) * 100);

    // Mettre à jour la session
    session.score = score;
    session.totalQuestions = totalQuestions;
    session.status = "completed";
    session.completedAt = new Date();
    await session.save();

    // Mettre à jour la progression
    const progress = await this.progressModel.findOne({
      kidId: session.kidId,
      lessonId: session.lessonId,
    });

    if (progress) {
      const wasCompleted = Boolean(progress.isCompleted);
      progress.attempts += 1;
      if (score > progress.bestScore) {
        progress.bestScore = score;
      }
      const willCompleteLesson = percentage >= 80;
      if (willCompleteLesson) {
        progress.isCompleted = true;
      }
      progress.lastAttemptAt = new Date();
      await progress.save();

      if (!wasCompleted && willCompleteLesson) {
        // Première validation de la leçon -> +5 points
        await this.rewardsService.addXP(
          kidIdFromToken,
          5,
          "lesson_complete",
          session._id.toString(),
          `Lesson completed for the first time.`,
        );
        await this.rewardsService.updateStreak(kidIdFromToken);
      }
    }

    // Attribuer l'XP selon le score
    const baseXP = 50; // XP de base pour terminer un quiz
    const scoreBonus = Math.round((score / totalQuestions) * 50); // Jusqu'à 50 XP bonus
    const totalXP = baseXP + scoreBonus;

    await this.rewardsService.addXP(
      kidIdFromToken,
      totalXP,
      "quiz",
      session._id.toString(),
      `Quiz completed: ${score}/${totalQuestions} (${percentage}%)`,
    );

    // Vérifier les badges liés aux quiz
    await this.rewardsService.checkQuizBadges(
      kidIdFromToken,
      score,
      totalQuestions,
    );

    await this.notificationsService.notifyParentOfKid(
      kidIdFromToken,
      NotificationType.CHILD_PROGRESS,
      "Quiz completed",
      `Your child completed a quiz: ${score}/${totalQuestions} (${percentage}%).`,
      {
        relatedId: session._id.toString(),
        relatedType: "quiz_session",
      },
    );

    if (totalXP > 0) {
      await this.notificationsService.notifyParentOfKid(
        kidIdFromToken,
        NotificationType.REWARD_EARNED,
        "Points earned",
        `+${totalXP} XP for this quiz!`,
        {
          relatedId: session._id.toString(),
          relatedType: "quiz_session",
        },
      );
    }

    return {
      score,
      totalQuestions,
      percentage,
      xpEarned: totalXP,
    };
  }

  async getQuestionsForQuizSession(sessionId: string, kidIdFromToken: string) {
    const session = await this.quizSessionModel.findById(sessionId).exec();
    if (!session) {
      throw new NotFoundException("Quiz session not found");
    }
    if (session.kidId.toString() !== kidIdFromToken) {
      throw new ForbiddenException("You can only load your own quiz session");
    }
    return this.getQuestionsForLesson(
      session.lessonId.toString(),
      session.difficultyFilter,
    );
  }

  /** Questions affichées à l'enfant (sans bonne réponse). L'ordre correspond au calcul du score dans submitQuiz. */
  async getQuestionsForLesson(lessonId: string, difficulty?: QuizDifficulty) {
    const lesson = await this.lessonsService.findOne(lessonId);
    if (!lesson) {
      throw new NotFoundException("Lesson not found");
    }

    const filter: Record<string, unknown> = {
      lessonId: new Types.ObjectId(lessonId),
      isActive: true,
    };
    if (difficulty) {
      filter.difficulty = difficulty;
    }

    const questions = await this.quizQuestionModel
      .find(filter)
      .sort({ createdAt: 1 })
      .select("question options difficulty")
      .lean()
      .exec();

    return questions.map((q, index) => ({
      questionIndex: index,
      question: q.question,
      options: q.options,
      difficulty: q.difficulty,
    }));
  }

  async getSessionById(sessionId: string, kidIdFromToken: string) {
    const session = await this.quizSessionModel.findById(sessionId);
    if (!session) {
      throw new NotFoundException("Quiz session not found");
    }

    // Vérification IDOR stricte
    if (session.kidId.toString() !== kidIdFromToken) {
      throw new ForbiddenException("Access denied");
    }

    return session;
  }

  private assertLessonEditAccess(
    lesson: { teacherId?: Types.ObjectId },
    userId: string,
    role: string,
  ) {
    if (role === UserRole.ADMIN) return;
    if (lesson.teacherId?.toString() === userId) return;
    throw new ForbiddenException(
      "You can only manage quiz questions for your own lessons",
    );
  }

  private mapQuestionAdmin(q: QuizQuestionDocument) {
    return {
      id: q._id.toString(),
      lessonId: q.lessonId.toString(),
      subjectId: q.subjectId?.toString(),
      question: q.question,
      options: q.options,
      correctAnswer: q.correctAnswer,
      difficulty: q.difficulty,
      explanation: q.explanation,
      isActive: q.isActive,
      createdAt: q.createdAt,
      updatedAt: q.updatedAt,
    };
  }

  async createTeacherQuizQuestion(
    lessonId: string,
    dto: CreateQuizQuestionDto,
    userId: string,
    role: string,
  ) {
    const lesson = await this.lessonsService.findOne(lessonId);
    if (!lesson) {
      throw new NotFoundException("Lesson not found");
    }
    this.assertLessonEditAccess(lesson, userId, role);
    if (dto.correctAnswer >= dto.options.length) {
      throw new BadRequestException(
        "correctAnswer must be a valid index in options",
      );
    }
    const doc = await this.quizQuestionModel.create({
      lessonId: new Types.ObjectId(lessonId),
      subjectId: lesson.subjectId,
      question: dto.question,
      options: dto.options,
      correctAnswer: dto.correctAnswer,
      difficulty: dto.difficulty ?? QuizDifficulty.MEDIUM,
      explanation: dto.explanation,
      isActive: true,
    });
    return this.mapQuestionAdmin(doc);
  }

  async listTeacherQuestionsForLesson(
    lessonId: string,
    userId: string,
    role: string,
  ) {
    const lesson = await this.lessonsService.findOne(lessonId);
    if (!lesson) {
      throw new NotFoundException("Lesson not found");
    }
    this.assertLessonEditAccess(lesson, userId, role);
    const qs = await this.quizQuestionModel
      .find({ lessonId: new Types.ObjectId(lessonId) })
      .sort({ createdAt: 1 })
      .exec();
    return qs.map((q) => this.mapQuestionAdmin(q));
  }

  async deleteTeacherQuestion(
    questionId: string,
    userId: string,
    role: string,
  ) {
    const q = await this.quizQuestionModel.findById(questionId);
    if (!q) {
      throw new NotFoundException("Question not found");
    }
    const lesson = await this.lessonsService.findOne(q.lessonId.toString());
    if (!lesson) {
      throw new NotFoundException("Lesson not found");
    }
    this.assertLessonEditAccess(lesson, userId, role);
    await this.quizQuestionModel.findByIdAndDelete(questionId);
  }
}
