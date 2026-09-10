import { Injectable, NotFoundException, BadRequestException, Inject, forwardRef } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Job, JobStatus } from './job.entity';
import { CreateJobDto, UpdateJobDto } from '@app/shared';
import { JobMatchingService } from './job-matching.service';

@Injectable()
export class JobsService {
  constructor(
    @InjectRepository(Job)
    private jobsRepository: Repository<Job>,
    @Inject(forwardRef(() => JobMatchingService))
    private jobMatchingService: JobMatchingService,
  ) {}

  async create(clientId: string, createJobDto: CreateJobDto): Promise<Job> {
    const job = this.jobsRepository.create({
      ...createJobDto,
      clientId,
      location: {
        type: 'Point',
        coordinates: [createJobDto.location.longitude, createJobDto.location.latitude],
      },
      status: 'searching',
    });
    const saved = await this.jobsRepository.save(job);
    this.jobMatchingService.startMatching(saved);
    return saved;
  }

  async findAll(): Promise<Job[]> {
    return this.jobsRepository.find({
      relations: ['client', 'handyman'],
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(id: string): Promise<Job> {
    const job = await this.jobsRepository.findOne({
      where: { id },
      relations: ['client', 'handyman'],
    });
    if (!job) {
      throw new NotFoundException(`Job with ID ${id} not found`);
    }
    return job;
  }

  async findByClientId(clientId: string): Promise<Job[]> {
    return this.jobsRepository.find({
      where: { clientId },
      relations: ['handyman'],
      order: { createdAt: 'DESC' },
    });
  }

  async findByHandymanId(handymanId: string): Promise<Job[]> {
    return this.jobsRepository.find({
      where: { handymanId },
      relations: ['client'],
      order: { createdAt: 'DESC' },
    });
  }

  async update(id: string, updateJobDto: UpdateJobDto): Promise<Job> {
    const job = await this.findOne(id);
    
    if (job.status === 'completed' || job.status === 'cancelled') {
      throw new BadRequestException('Cannot update completed or cancelled job');
    }

    Object.assign(job, updateJobDto);
    
    if (updateJobDto.status === 'in_progress') {
      job.startedAt = new Date();
    } else if (updateJobDto.status === 'completed') {
      job.completedAt = new Date();
    }

    if (updateJobDto.status === 'completed' || updateJobDto.status === 'cancelled') {
      this.jobMatchingService.stopMatching(id);
    }
    
    return this.jobsRepository.save(job);
  }

  async acceptJob(jobId: string, handymanId: string): Promise<Job> {
    const job = await this.findOne(jobId);
    
    if (job.status !== 'searching' && job.status !== 'matched') {
      throw new BadRequestException('Job is not available for acceptance');
    }

    job.handymanId = handymanId;
    job.status = 'accepted';

    this.jobMatchingService.stopMatching(jobId);
    
    return this.jobsRepository.save(job);
  }

  async cancelJob(id: string, userId: string): Promise<Job> {
    const job = await this.findOne(id);
    
    if (job.clientId !== userId && job.handymanId !== userId) {
      throw new BadRequestException('You can only cancel your own jobs');
    }

    if (job.status === 'completed') {
      throw new BadRequestException('Cannot cancel completed job');
    }

    job.status = 'cancelled';

    this.jobMatchingService.stopMatching(id);
    
    return this.jobsRepository.save(job);
  }
}
