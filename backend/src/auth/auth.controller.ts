import { Controller, Post, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  async register(@Body() body: any) {
    return this.authService.register(body);
  }

  @HttpCode(HttpStatus.OK)
  @Post('login')
  async login(@Body() body: any) {
    return this.authService.login(body);
  }

  @Post('send-email-otp')
  async sendEmailOtp(@Body() body: any) {
    return this.authService.sendEmailOtp(body.email);
  }

  @Post('verify-email-otp')
  async verifyEmailOtp(@Body() body: any) {
    return this.authService.verifyEmailOtp(body.email, body.otp);
  }
}
