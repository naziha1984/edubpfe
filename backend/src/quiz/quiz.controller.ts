import {
  Controller,
  Post,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { QuizService } from './quiz.service';
import { CreateSessionDto } from './dto/create-session.dto';
import { SubmitQuizDto } from './dto/submit-quiz.dto';
import { KidAuthGuard } from '../kids/guards/kid-auth.guard';
import { GetKid } from '../kids/decorators/get-kid.decorator';

@Controller('quiz')
export class QuizController {
  constructor(private readonly quizService: QuizService) {}

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
  async submitQuiz(
    @Body() submitQuizDto: SubmitQuizDto,
    @GetKid() kid: any,
  ) {
    const result = await this.quizService.submitQuiz(
      submitQuizDto,
      kid.kidId,
    );

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
