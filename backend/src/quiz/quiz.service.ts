import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { QuizSession, QuizSessionDocument } from './schemas/quiz-session.schema';
import { Progress, ProgressDocument } from './schemas/progress.schema';
import { QuizQuestion, QuizQuestionDocument } from './schemas/quiz-question.schema';
import { CreateSessionDto } from './dto/create-session.dto';
import { SubmitQuizDto } from './dto/submit-quiz.dto';
import { LessonsService } from '../subjects/lessons.service';
import { SubjectsService } from '../subjects/subjects.service';
import { RewardsService } from '../rewards/rewards.service';

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
  ) {}

  async createSession(createSessionDto: CreateSessionDto, kidIdFromToken: string) {
    // Strict IDOR check: kidId from token must match kidId from request
    if (createSessionDto.kidId !== kidIdFromToken) {
      throw new ForbiddenException('You can only create sessions for yourself');
    }

    // Verify lesson exists
    const lesson = await this.lessonsService.findOne(createSessionDto.lessonId);
    if (!lesson) {
      throw new NotFoundException('Lesson not found');
    }

    // Get subject from lesson
    const subject = await this.subjectsService.findOne(
      lesson.subjectId.toString(),
    );
    if (!subject) {
      throw new NotFoundException('Subject not found');
    }

    // Create or update progress
    const progress = await this.progressModel.findOneAndUpdate(
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

    // Create quiz session
    const session = new this.quizSessionModel({
      kidId: new Types.ObjectId(kidIdFromToken),
      lessonId: new Types.ObjectId(createSessionDto.lessonId),
      status: 'in_progress',
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
    // Get session
    const session = await this.quizSessionModel.findById(
      submitQuizDto.sessionId,
    );
    if (!session) {
      throw new NotFoundException('Quiz session not found');
    }

    // Strict IDOR check: session must belong to the kid from token
    if (session.kidId.toString() !== kidIdFromToken) {
      throw new ForbiddenException(
        'You can only submit quizzes for your own sessions',
      );
    }

    if (session.status === 'completed') {
      throw new BadRequestException('Quiz session already completed');
    }

    // Get questions for the lesson
    const questions = await this.quizQuestionModel
      .find({
        lessonId: session.lessonId,
        isActive: true,
      })
      .sort({ createdAt: 1 })
      .exec();

    if (questions.length === 0) {
      throw new NotFoundException('No questions found for this lesson');
    }

    // Calculate score
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

    // Update session
    session.score = score;
    session.totalQuestions = totalQuestions;
    session.status = 'completed';
    session.completedAt = new Date();
    await session.save();

    // Update progress
    const progress = await this.progressModel.findOne({
      kidId: session.kidId,
      lessonId: session.lessonId,
    });

    if (progress) {
      progress.attempts += 1;
      if (score > progress.bestScore) {
        progress.bestScore = score;
      }
      if (percentage >= 80) {
        progress.isCompleted = true;
      }
      progress.lastAttemptAt = new Date();
      await progress.save();
    }

    // Award XP based on score
    const baseXP = 50; // Base XP for completing a quiz
    const scoreBonus = Math.round((score / totalQuestions) * 50); // Up to 50 bonus XP
    const totalXP = baseXP + scoreBonus;

    await this.rewardsService.addXP(
      kidIdFromToken,
      totalXP,
      'quiz',
      session._id.toString(),
      `Quiz completed: ${score}/${totalQuestions} (${percentage}%)`,
    );

    // Check for quiz-related badges
    await this.rewardsService.checkQuizBadges(kidIdFromToken, score, totalQuestions);

    return {
      score,
      totalQuestions,
      percentage,
      xpEarned: totalXP,
    };
  }

  async getSessionById(sessionId: string, kidIdFromToken: string) {
    const session = await this.quizSessionModel.findById(sessionId);
    if (!session) {
      throw new NotFoundException('Quiz session not found');
    }

    // Strict IDOR check
    if (session.kidId.toString() !== kidIdFromToken) {
      throw new ForbiddenException('Access denied');
    }

    return session;
  }
}
