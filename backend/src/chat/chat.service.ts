import { Injectable, ForbiddenException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { GroupCategory } from '@prisma/client';

@Injectable()
export class ChatService {
  constructor(private prisma: PrismaService) {}

  // 1. CREATE GROUP (Only SUPER_ADMIN)
  async createGroup(adminId: string, groupName: string, category: GroupCategory, memberIds: string[]) {
    // Check if user is admin
    const admin = await this.prisma.user.findUnique({ where: { id: adminId } });
    if (admin?.role !== 'SUPER_ADMIN') {
      throw new ForbiddenException('Only the Admin can create groups');
    }

    // Create the conversation
    const conversation = await this.prisma.conversation.create({
      data: {
        type: 'GROUP',
        groupName,
        category,
        participants: {
          create: [
            { userId: adminId, role: 'SUPER_ADMIN' },
            ...memberIds.map(id => ({ userId: id, role: 'MEMBER' as const }))
          ]
        }
      },
      include: { participants: true }
    });

    return conversation;
  }

  // 2. SEND MESSAGE (Any user, if not restricted)
  async sendMessage(senderId: string, conversationId: string, text: string) {
    const sender = await this.prisma.user.findUnique({ where: { id: senderId } });
    const conversation = await this.prisma.conversation.findUnique({ where: { id: conversationId } });

    if (!conversation) throw new NotFoundException('Chat not found');

    if (conversation.onlyAdminsCanMessage && sender?.role !== 'SUPER_ADMIN') {
      throw new ForbiddenException('Only the Admin can send messages in this group');
    }

    const message = await this.prisma.message.create({
      data: {
        conversationId,
        senderId,
        encryptedPayload: text, // Assuming text is sent securely for now
      },
      include: { sender: true }
    });

    return message;
  }

  // 3. EDIT MESSAGE (Only SUPER_ADMIN)
  async editMessage(adminId: string, messageId: string, newText: string) {
    const admin = await this.prisma.user.findUnique({ where: { id: adminId } });
    if (admin?.role !== 'SUPER_ADMIN') {
      throw new ForbiddenException('Only the Admin can edit messages');
    }

    return this.prisma.message.update({
      where: { id: messageId },
      data: {
        encryptedPayload: newText,
        isEdited: true,
      }
    });
  }

  // 4. DELETE MESSAGE (Only SUPER_ADMIN)
  async deleteMessage(adminId: string, messageId: string) {
    const admin = await this.prisma.user.findUnique({ where: { id: adminId } });
    if (admin?.role !== 'SUPER_ADMIN') {
      throw new ForbiddenException('Only the Admin can delete messages');
    }

    return this.prisma.message.update({
      where: { id: messageId },
      data: {
        encryptedPayload: 'This message was deleted by Admin',
        isDeleted: true,
      }
    });
  }
}
