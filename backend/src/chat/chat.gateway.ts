import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { ChatService } from './chat.service';
import { GroupCategory } from '@prisma/client';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  constructor(private readonly chatService: ChatService) {}

  handleConnection(client: Socket) {
    console.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    console.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('joinRoom')
  handleJoinRoom(
    @ConnectedSocket() client: Socket,
    @MessageBody() roomId: string,
  ) {
    client.join(roomId);
    return { event: 'joined', data: roomId };
  }

  @SubscribeMessage('sendMessage')
  async handleMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { senderId: string; conversationId: string; text: string },
  ) {
    try {
      const message = await this.chatService.sendMessage(
        payload.senderId,
        payload.conversationId,
        payload.text,
      );
      this.server.to(payload.conversationId).emit('newMessage', message);
      return message;
    } catch (error) {
      client.emit('error', { message: error.message });
    }
  }

  @SubscribeMessage('editMessage')
  async handleEditMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { adminId: string; messageId: string; newText: string; conversationId: string },
  ) {
    try {
      const message = await this.chatService.editMessage(
        payload.adminId,
        payload.messageId,
        payload.newText,
      );
      this.server.to(payload.conversationId).emit('messageEdited', message);
      return message;
    } catch (error) {
      client.emit('error', { message: error.message });
    }
  }

  @SubscribeMessage('deleteMessage')
  async handleDeleteMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { adminId: string; messageId: string; conversationId: string },
  ) {
    try {
      const message = await this.chatService.deleteMessage(
        payload.adminId,
        payload.messageId,
      );
      this.server.to(payload.conversationId).emit('messageDeleted', message);
      return message;
    } catch (error) {
      client.emit('error', { message: error.message });
    }
  }

  @SubscribeMessage('createGroup')
  async handleCreateGroup(
    @ConnectedSocket() client: Socket,
    @MessageBody() payload: { adminId: string; groupName: string; category: GroupCategory; memberIds: string[] },
  ) {
    try {
      const group = await this.chatService.createGroup(
        payload.adminId,
        payload.groupName,
        payload.category,
        payload.memberIds,
      );
      // Notify all added members (assuming they are connected and joined a generic personal room)
      payload.memberIds.forEach(id => {
        this.server.to(`user_${id}`).emit('groupCreated', group);
      });
      return group;
    } catch (error) {
      client.emit('error', { message: error.message });
    }
  }
}
