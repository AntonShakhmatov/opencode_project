import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../users/user.entity';
import { Job } from '../jobs/job.entity';
import { Review } from '../reviews/review.entity';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    @InjectRepository(Job)
    private jobsRepository: Repository<Job>,
    @InjectRepository(Review)
    private reviewsRepository: Repository<Review>,
  ) {}

  async getDashboardStats() {
    const totalUsers = await this.usersRepository.count();
    const totalHandymen = await this.usersRepository.count({ where: { role: 'handyman' } });
    const totalClients = await this.usersRepository.count({ where: { role: 'client' } });
    const totalJobs = await this.jobsRepository.count();
    const activeJobs = await this.jobsRepository.count({
      where: [
        { status: 'searching' },
        { status: 'matched' },
        { status: 'accepted' },
        { status: 'en_route' },
        { status: 'in_progress' },
      ],
    });
    const completedJobs = await this.jobsRepository.count({ where: { status: 'completed' } });
    const totalReviews = await this.reviewsRepository.count();

    return {
      totalUsers,
      totalHandymen,
      totalClients,
      totalJobs,
      activeJobs,
      completedJobs,
      totalReviews,
    };
  }

  async getRecentJobs(limit = 10) {
    return this.jobsRepository.find({
      relations: ['client', 'handyman'],
      order: { createdAt: 'DESC' },
      take: limit,
    });
  }
}
