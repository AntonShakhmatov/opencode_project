import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { compare, hash } from 'bcrypt';
import { UsersService } from '../users/users.service';
import { LoginDto, RegisterDto } from './dto/auth.dto';
import { AuthResponse, UserRole } from '@app/shared';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  async login(loginDto: LoginDto): Promise<AuthResponse> {
    const user = await this.usersService.findByEmail(loginDto.email);
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const passwordValid = await compare(loginDto.password, user.password);
    if (!passwordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    return this.buildAuthResponse(user);
  }

  async register(registerDto: RegisterDto): Promise<AuthResponse> {
    const hashedPassword = await hash(registerDto.password, 10);

    let user;
    try {
      user = await this.usersService.create({
        ...registerDto,
        password: hashedPassword,
      });
    } catch (error) {
      if (error instanceof ConflictException) {
        throw error;
      }
      throw error;
    }

    return this.buildAuthResponse(user);
  }

  async refresh(refreshToken: string): Promise<AuthResponse> {
    let payload: any;
    try {
      payload = await this.jwtService.verifyAsync(refreshToken, {
        secret: this.configService.get<string>('JWT_SECRET', 'handyman-test-secret-key-2024'),
      });
    } catch {
      throw new UnauthorizedException('Invalid refresh token');
    }

    if (payload.type !== 'refresh') {
      throw new UnauthorizedException('Invalid refresh token');
    }

    const user = await this.usersService.findOne(payload.sub);
    return this.buildAuthResponse(user);
  }

  async me(userId: string) {
    const user = await this.usersService.findOne(userId);
    return {
      id: user.id,
      email: user.email,
      name: user.name,
      phone: user.phone,
      role: user.role,
      avatar: user.avatar,
      rating: user.rating,
      reviewCount: user.reviewCount,
      skills: user.skills,
      isAvailable: user.isAvailable,
    };
  }

  private async buildAuthResponse(user: any): Promise<AuthResponse> {
    const secret = this.configService.get<string>(
      'JWT_SECRET',
      'handyman-test-secret-key-2024',
    );
    const basePayload = {
      sub: user.id,
      email: user.email,
      role: user.role as UserRole,
    };

    const accessToken = await this.jwtService.signAsync(basePayload, {
      secret,
      expiresIn: '1d',
    });
    const refreshToken = await this.jwtService.signAsync(
      { ...basePayload, type: 'refresh' },
      { secret, expiresIn: '7d' },
    );

    return {
      accessToken,
      refreshToken,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role as UserRole,
      },
    };
  }
}