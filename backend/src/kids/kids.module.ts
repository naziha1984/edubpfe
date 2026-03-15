import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigService } from '../config/config.service';
import { KidsController } from './kids.controller';
import { KidDemoController } from './kid-demo.controller';
import { KidsService } from './kids.service';
import { Kid, KidSchema } from './schemas/kid.schema';
import { KidJwtStrategy } from './strategies/kid-jwt.strategy';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Kid.name, schema: KidSchema }]),
    PassportModule,
    JwtModule.registerAsync({
      useFactory: (configService: ConfigService) => ({
        secret: configService.jwtSecret,
        signOptions: { expiresIn: '30m' },
      }),
      inject: [ConfigService],
    }),
  ],
  controllers: [KidsController, KidDemoController],
  providers: [KidsService, KidJwtStrategy],
  exports: [KidsService],
})
export class KidsModule {}
