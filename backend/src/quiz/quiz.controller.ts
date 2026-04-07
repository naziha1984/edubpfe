import {
  Controller,
  Post,
  Get,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { QuizService } from './quiz.service';
import { CreateSessionDto } from './dto/create-session.dto';
import { SubmitQuizDto } from './dto/submit-quiz.dto';
import { CreateQuizQuestionDto } from './dto/create-quiz-question.dto';
import { KidAuthGuard } from '../kids/guards/kid-auth.guard';
import { GetKid } from '../kids/decorators/get-kid.decorator';
import { QuizDifficulty } from './schemas/quiz-question.schema';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/schemas/user.schema';
import { GetUser } from '../auth/decorators/get-user.decorator';

@Controller('quiz')
export class QuizController {
  constructor(private readonly quizService: QuizService) {}

  @Get('sessions/:sessionId/questions')
  @UseGuards(KidAuthGuard)
  async getSessionQuestions(
    @Param('sessionId') sessionId: string,
    @GetKid() kid: any,
  ) {
    return this.quizService.getQuestionsForQuizSession(
      sessionId,
      kid.kidId,
    );
  }

  @Get('lessons/:lessonId/questions')
  @UseGuards(KidAuthGuard)
  async getLessonQuestions(
    @Param('lessonId') lessonId: string,
    @Query('difficulty') difficulty: QuizDifficulty | undefined,
    @GetKid() _kid: any,
  ) {
    return this.quizService.getQuestionsForLesson(lessonId, difficulty);
  }

  @Post('sessions')
  @UseGuards(KidAuthGuard)
  @HttpCode(HttpStatus.CREATED)
  async createSession(
    @Body() createSessionDto: CreateSessionDto,
    @GetKid() kid: any,
  ) {
    const session = await this.quizService.createSession(
      createSessionDto,
      kid.kidId,
    );

    return {
      id: session._id.toString(),
      kidId: session.kidId.toString(),
      lessonId: session.lessonId.toString(),
      status: session.status,
      createdAt: session.createdAt,
    };
  }

  @Post('submit')
  @UseGuards(KidAuthGuard)
  @HttpCode(HttpStatus.OK)
  async submitQuiz(@Body() submitQuizDto: SubmitQuizDto, @GetKid() kid: any) {
    const result = await this.quizService.submitQuiz(submitQuizDto, kid.kidId);

    return {
      sessionId: submitQuizDto.sessionId,
      score: result.score,
      totalQuestions: result.totalQuestions,
      percentage: result.percentage,
      passed: result.percentage >= 80,
      xpEarned: result.xpEarned,
    };
  }
}
