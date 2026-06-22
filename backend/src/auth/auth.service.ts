import { Injectable, UnauthorizedException, ConflictException, ForbiddenException, OnModuleInit } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';
import * as argon2 from 'argon2';
import * as nodemailer from 'nodemailer';

@Injectable()
export class AuthService implements OnModuleInit {
  private transporter;

  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {
    this.transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
    });
  }

  async onModuleInit() {
    // Seed the static SUPER_ADMIN user
    const adminEmail = 'admin@mychat.com';
    const adminUser = await this.prisma.user.findUnique({ where: { email: adminEmail } });
    if (!adminUser) {
      const passwordHash = await argon2.hash('admin123');
      await this.prisma.user.create({
        data: {
          email: adminEmail,
          fullName: 'Super Admin',
          passwordHash,
          role: 'SUPER_ADMIN',
          bio: 'App Administrator',
        },
      });
      console.log('Static SUPER_ADMIN seeded successfully.');
    }
  }

  async sendEmailOtp(email: string) {
    if (!email) throw new ConflictException('Email is required');
    
    // Generate 6 digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 10 * 60000); // 10 minutes from now

    // Save or update OTP in DB
    await this.prisma.otpToken.upsert({
      where: { email },
      update: { otp, expiresAt },
      create: { email, otp, expiresAt },
    });

    // Send email
    try {
      await this.transporter.sendMail({
        from: `"MyCHAT App" <${process.env.EMAIL_USER}>`,
        to: email,
        subject: 'Your MyCHAT Verification Code',
        text: `Your OTP is: ${otp}. It will expire in 10 minutes.`,
        html: `<h3>Your MyCHAT Verification Code</h3><p>Your OTP is: <strong>${otp}</strong></p><p>It will expire in 10 minutes.</p>`,
      });
      return { message: 'OTP sent successfully' };
    } catch (error) {
      console.error('Failed to send email:', error);
      throw new ConflictException('Failed to send email OTP. Please check your email configuration.');
    }
  }

  async verifyEmailOtp(email: string, otp: string) {
    if (!email || !otp) throw new ConflictException('Email and OTP are required');

    const record = await this.prisma.otpToken.findUnique({ where: { email } });
    if (!record) throw new UnauthorizedException('No OTP found for this email');

    if (record.otp !== otp) throw new UnauthorizedException('Invalid OTP');
    if (record.expiresAt < new Date()) throw new UnauthorizedException('OTP has expired');

    // Delete OTP after successful verification so it can't be reused
    await this.prisma.otpToken.delete({ where: { email } });

    return { message: 'OTP verified successfully' };
  }

  async register(data: any) {
    const { phoneNumber, email, password, fullName } = data;

    if (!phoneNumber && !email) {
      throw new ConflictException('Must provide either email or phone number');
    }

    // 100 User Limit Check
    const userCount = await this.prisma.user.count();
    if (userCount >= 100) {
      throw new ForbiddenException('App capacity reached. No more than 100 members are allowed.');
    }

    const existingUser = await this.prisma.user.findFirst({
      where: {
        OR: [
          { email: email || undefined },
          { phoneNumber: phoneNumber || undefined }
        ]
      }
    });

    if (existingUser) {
      throw new ConflictException('User already exists');
    }

    const passwordHash = await argon2.hash(password);

    const user = await this.prisma.user.create({
      data: {
        phoneNumber,
        email,
        fullName,
        passwordHash,
      },
    });

    return this.generateTokens(user.id, data.deviceId);
  }

  async login(data: any) {
    const { identifier, password, deviceId } = data; // identifier is email or phone

    const user = await this.prisma.user.findFirst({
      where: {
        OR: [
          { email: identifier },
          { phoneNumber: identifier },
        ],
      },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const isPasswordValid = await argon2.verify(user.passwordHash, password);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    return this.generateTokens(user.id, deviceId);
  }

  private async generateTokens(userId: string, deviceId: string) {
    const payload = { sub: userId };
    const accessToken = this.jwtService.sign(payload, { expiresIn: '15m' });
    const refreshToken = this.jwtService.sign(payload, { expiresIn: '7d' });

    await this.prisma.session.upsert({
      where: {
        deviceId: deviceId, // assuming one session per device
      },
      update: {
        userId,
        refreshToken,
        lastActive: new Date(),
      },
      create: {
        userId,
        deviceId,
        refreshToken,
      },
    });

    return {
      accessToken,
      refreshToken,
      userId,
    };
  }
}
