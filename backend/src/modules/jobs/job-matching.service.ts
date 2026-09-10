import { Injectable, Logger, Inject, forwardRef } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JobsService } from './jobs.service';
import { LocationService } from '../location/location.service';
import { ChatGateway } from '../chat/chat.gateway';
import { Job } from './job.entity';

interface MatchingStep {
  radius: number;
  delay: number;
}

@Injectable()
export class JobMatchingService {
  private readonly logger = new Logger(JobMatchingService.name);
  private timers = new Map<string, NodeJS.Timeout>();

  private readonly steps: MatchingStep[] = [
    { radius: 1000, delay: 0 },
    { radius: 3000, delay: 20000 },
    { radius: 5000, delay: 20000 },
    { radius: 10000, delay: 30000 },
    { radius: 20000, delay: 30000 },
    { radius: 50000, delay: 60000 },
  ];

  constructor(
    @Inject(forwardRef(() => JobsService))
    private jobsService: JobsService,
    private locationService: LocationService,
    private chatGateway: ChatGateway,
    private configService: ConfigService,
  ) {}

  startMatching(job: Job) {
    this.stopMatching(job.id);
    this.logger.log(`Started matching for job ${job.id} (${job.serviceType})`);
    this.chatGateway.emitToJob(job.id, 'matchingStarted', { jobId: job.id });
    this.runStep(job.id, 0);
  }

  stopMatching(jobId: string) {
    const timer = this.timers.get(jobId);
    if (timer) {
      clearTimeout(timer);
      this.timers.delete(jobId);
      this.logger.log(`Stopped matching for job ${jobId}`);
    }
  }

  private runStep(jobId: string, index: number) {
    if (index >= this.steps.length) {
      this.chatGateway.emitToJob(jobId, 'matchingFailed', {
        jobId,
        message: 'No handymen found within the maximum radius',
      });
      this.logger.log(`Matching exhausted for job ${jobId}`);
      return;
    }

    const step = this.steps[index];

    this.timers.set(
      jobId,
      setTimeout(() => {
        this.timers.delete(jobId);

        this.executeStep(jobId, index);
      }, step.delay),
    );
  }

  private async executeStep(jobId: string, index: number) {
    let current: Job;
    try {
      current = await this.jobsService.findOne(jobId);
    } catch {
      return;
    }

    if (current.status !== 'searching') {
      return;
    }

    const step = this.steps[index];
    const location = {
      latitude: current.location.coordinates[1],
      longitude: current.location.coordinates[0],
    };

    const handymen = await this.locationService.findNearbyHandymen(
      location,
      step.radius,
      current.serviceType,
    );

    this.logger.log(
      `Job ${jobId}: search radius ${step.radius}m found ${handymen.length} handymen`,
    );

    if (handymen.length > 0) {
      const handyman = handymen[0];
      await this.jobsService.update(jobId, {
        status: 'matched',
        handymanId: handyman.userId,
      });

      const matchDelay = this.configService.get<number>(
        'MATCH_NOTIFY_DELAY_MS',
        2500,
      );

      this.timers.set(
        jobId,
        setTimeout(() => {
          this.timers.delete(jobId);
          this.chatGateway.emitToJob(jobId, 'handymanFound', {
            jobId,
            handymen,
          });
        }, matchDelay),
      );

      this.chatGateway.emitToUser(handyman.userId, 'jobOffered', {
        jobId,
        serviceType: current.serviceType,
        description: current.description,
        address: current.address,
        offeredJobId: jobId,
      });
      this.logger.log(`Job ${jobId} matched with handyman ${handyman.userId}`);
      return;
    }

    this.runStep(jobId, index + 1);
  }
}