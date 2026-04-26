import { Injectable, ExecutionContext } from "@nestjs/common";
import { AuthGuard } from "@nestjs/passport";

@Injectable()
export class ProgressAuthGuard extends AuthGuard(["jwt", "kid-jwt"]) {
  canActivate(context: ExecutionContext) {
    // Try both strategies - if either succeeds, allow access
    return super.canActivate(context);
  }

  handleRequest(err: any, user: any, _info: any, _context: ExecutionContext) {
    // Paramètres non utilisés, conservés pour respecter la signature Passport.
    void _info;
    void _context;

    // Return user if either strategy succeeded
    if (user) {
      return user;
    }
    // If no user from either strategy, throw error
    throw err || new Error("Authentication required");
  }
}
