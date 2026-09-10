import { Module, OnModuleInit } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';
import { User } from './user.entity';
import { hash } from 'bcrypt';

@Module({
  imports: [TypeOrmModule.forFeature([User])],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule implements OnModuleInit {
  constructor(private readonly usersService: UsersService) {}

  async onModuleInit() {
    await this.seed();
  }

  private async seed() {
    const existingUsers = await this.usersService.findAll();
    if (existingUsers.length > 0) {
      return;
    }

    console.log('Seeding users...');

    const hashedPassword = await hash('password123', 10);

    await this.usersService.create({
      email: 'admin@handyman.com',
      name: 'Admin User',
      password: hashedPassword,
      role: 'admin',
    });

    await this.usersService.create({
      email: 'client@test.com',
      name: 'Test Client',
      password: hashedPassword,
      role: 'client',
      phone: '+1234567890',
    });

    await this.usersService.create({
      email: 'client2@test.com',
      name: 'Jane Client',
      password: hashedPassword,
      role: 'client',
      phone: '+1234567891',
    });

    const handymen = [
      { email: 'plumber@test.com', name: 'Mike Plumber', skills: ['plumbing', 'general_repair'], lat: 40.7128, lng: -74.0060 },
      { email: 'electrician@test.com', name: 'John Electrician', skills: ['electrical', 'appliance_repair'], lat: 40.7138, lng: -74.0050 },
      { email: 'carpenter@test.com', name: 'Tom Carpenter', skills: ['carpentry', 'painting'], lat: 40.7148, lng: -74.0040 },
      { email: 'cleaner@test.com', name: 'Sarah Cleaner', skills: ['cleaning', 'landscaping'], lat: 40.7158, lng: -74.0030 },
    ];

    for (const handyman of handymen) {
      const user = await this.usersService.create({
        email: handyman.email,
        name: handyman.name,
        password: hashedPassword,
        role: 'handyman',
        skills: handyman.skills,
      });

      await this.usersService.update(user.id, {
        isAvailable: true,
        location: {
          type: 'Point',
          coordinates: [handyman.lng, handyman.lat],
        },
      });
    }

    console.log('Users seeded successfully!');
  }
}
