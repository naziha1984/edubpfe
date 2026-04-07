import {
  WebSocketGateway,
  WebSocketServer,
  OnGatewayInit,
  OnGatewayConnection,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { NotificationsService } from './notifications.service';

/**
 * Parent / teacher real-time channel (JWT utilisateur, pas kid).
 * Flutter: Socket.IO client sur même host, namespace `/notifications`,
 * auth: { token: '<JWT>' } ou query ?token=
 */
@WebSocketGateway({
  cors: { origin: '*' },
  namespace: '/notifications',
})
export class NotificationsGateway
  implements OnGatewayInit, OnGatewayConnection
{
  @WebSocketServer()
  server: Server;

  constructor(
    private readonly jwtService: JwtService,
    private readonly notificationsService: NotificationsService,
  ) {}

  afterInit() {
    this.notificationsService.attachGateway(this);
  }

  handleConnection(client: Socket) {
    const fromAuth = client.handshake.auth?.token;
    const fromQuery = client.handshake.query?.token;
    const header = client.handshake.headers?.authorization;
    let raw: string | undefined;
    if (typeof fromAuth === 'string') raw = fromAuth;
    else if (typeof fromQuery === 'string') raw = fromQuery;
    else if (typeof header === 'string' && header.startsWith('Bearer ')) {
      raw = header.slice(7);
    }
    if (!raw) {
      client.disconnect();
      return;
    }
    try {
      const payload = this.jwtService.verify<{ sub: string }>(raw);
      client.join(`user:${payload.sub}`);
    } catch {
      client.disconnect();
    }
  }

  emitToUser(userId: string, payload: Record<string, unknown>) {
    this.server.to(`user:${userId}`).emit('notification', payload);
  }
}
