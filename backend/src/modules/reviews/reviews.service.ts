import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Review } from './review.entity';
import { CreateReviewDto } from '@app/shared';
import { UsersService } from '../users/users.service';

@Injectable()
export class ReviewsService {
  constructor(
    @InjectRepository(Review)
    private reviewsRepository: Repository<Review>,
    private usersService: UsersService,
  ) {}

  async create(reviewerId: string, createReviewDto: CreateReviewDto): Promise<Review> {
    const review = this.reviewsRepository.create({
      ...createReviewDto,
      reviewerId,
    });
    const savedReview = await this.reviewsRepository.save(review);
    
    await this.updateHandymanRating(createReviewDto.revieweeId);
    
    return savedReview;
  }

  async findAll(): Promise<Review[]> {
    return this.reviewsRepository.find({
      relations: ['reviewer', 'reviewee'],
      order: { createdAt: 'DESC' },
    });
  }

  async findByJobId(jobId: string): Promise<Review[]> {
    return this.reviewsRepository.find({
      where: { jobId },
      relations: ['reviewer', 'reviewee'],
    });
  }

  async findByRevieweeId(revieweeId: string): Promise<Review[]> {
    return this.reviewsRepository.find({
      where: { revieweeId },
      relations: ['reviewer'],
      order: { createdAt: 'DESC' },
    });
  }

  private async updateHandymanRating(handymanId: string): Promise<void> {
    const result = await this.reviewsRepository
      .createQueryBuilder('review')
      .select('AVG(review.rating)', 'avg')
      .addSelect('COUNT(*)', 'count')
      .where('review.revieweeId = :handymanId', { handymanId })
      .getRawOne();

    await this.usersService.update(handymanId, {
      rating: parseFloat(result.avg) || 0,
      reviewCount: parseInt(result.count) || 0,
    });
  }
}
