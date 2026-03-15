import { Injectable, ExecutionContext } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

@Injectable()
export class ProgressAuthGuard extends AuthGuard(['jwt', 'kid-jwt']) {
  canActivate(context: ExecutionContext) {
    // Try both strategies - if either succeeds, allow access
    return super.canActivate(context);
  }

  handleRequest(err: any, user: any, info: any, context: ExecutionContext) {
    // Return user if either strategy succeeded
    if (user) {
      return user;
    }
    // If no user from either strategy, throw error
    throw err || new Error('Authentication required');
  }
}
