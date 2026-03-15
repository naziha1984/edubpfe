import { Controller, Get, UseGuards } from '@nestjs/common';
import { KidAuthGuard } from './guards/kid-auth.guard';
import { GetKid } from './decorators/get-kid.decorator';

@Controller('kid-demo')
export class KidDemoController {
  @Get('me')
  @UseGuards(KidAuthGuard)
  async getKidInfo(@GetKid() kid: any) {
    return {
      message: `Hello ${kid.firstName} ${kid.lastName}!`,
      kidId: kid.kidId,
      firstName: kid.firstName,
      lastName: kid.lastName,
      parentId: kid.parentId,
    };
  }

  @Get('protected')
  @UseGuards(KidAuthGuard)
  async protectedRoute(@GetKid() kid: any) {
    return {
      message: 'This is a protected route for kids',
      kid: {
        id: kid.kidId,
        name: `${kid.firstName} ${kid.lastName}`,
      },
    };
  }
}
