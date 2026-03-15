import { NestFactory } from '@nestjs/core';
import { AppModule } from '../app.module';
import { UsersService } from '../users/users.service';
import { UserRole } from '../users/schemas/user.schema';
import { Logger } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const logger = new Logger('Seed');
  const usersService = app.get(UsersService);

  try {
    // Check if ADMIN exists
    const adminExists = await usersService.findByEmail('admin@edubridge.com');
    if (!adminExists) {
      await usersService.create(
        'admin@edubridge.com',
        'admin123',
        'Admin',
        'User',
        UserRole.ADMIN,
      );
      logger.log('✅ ADMIN user created: admin@edubridge.com / admin123');
    } else {
      logger.log('ℹ️  ADMIN user already exists');
    }

    // Check if TEACHER exists
    const teacherExists = await usersService.findByEmail(
      'teacher@edubridge.com',
    );
    if (!teacherExists) {
      await usersService.create(
        'teacher@edubridge.com',
        'teacher123',
        'Teacher',
        'User',
        UserRole.TEACHER,
      );
      logger.log('✅ TEACHER user created: teacher@edubridge.com / teacher123');
    } else {
      logger.log('ℹ️  TEACHER user already exists');
    }

    logger.log('🎉 Seed completed successfully!');
  } catch (error) {
    logger.error('❌ Seed failed:', error);
  } finally {
    await app.close();
  }
}

bootstrap();
