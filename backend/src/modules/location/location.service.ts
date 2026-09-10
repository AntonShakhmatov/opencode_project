import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../users/user.entity';
import { NearbyHandyman, GeoLocation } from '@app/shared';

@Injectable()
export class LocationService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  async updateLocation(userId: string, location: GeoLocation): Promise<void> {
    const point = JSON.stringify({
      type: 'Point',
      coordinates: [location.longitude, location.latitude],
    });
    
    await this.usersRepository
      .createQueryBuilder()
      .update(User)
      .set({ location: () => `ST_GeomFromGeoJSON('${point}')` })
      .where('id = :userId', { userId })
      .execute();
  }

  async findNearbyHandymen(
    location: GeoLocation,
    radiusInMeters: number,
    serviceType?: string,
  ): Promise<NearbyHandyman[]> {
    const query = this.usersRepository
      .createQueryBuilder('user')
      .select([
        'user.id as "userId"',
        'user.name as name',
        'user.avatar as avatar',
        'user.rating as rating',
        'user.skills as skills',
        'ST_AsGeoJSON(user.location)::json as location',
        'ST_Distance(user.location, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography) as "distanceInMeters"',
      ])
      .where('user.role = :role', { role: 'handyman' })
      .andWhere('user.isAvailable = true')
      .andWhere(
        'ST_DWithin(user.location, ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography, :radius)',
        { lng: location.longitude, lat: location.latitude, radius: radiusInMeters },
      )
      .setParameters({ lng: location.longitude, lat: location.latitude });

    if (serviceType) {
      query.andWhere(':serviceType = ANY(string_to_array(user.skills, \',\'))', { serviceType });
    }

    query.orderBy('"distanceInMeters"', 'ASC');

    const results = await query.getRawMany();
    
    return results.map((r) => ({
      userId: r.userId,
      name: r.name,
      avatar: r.avatar,
      rating: r.rating ? parseFloat(r.rating) : null,
      skills: r.skills,
      location: r.location,
      distanceInMeters: parseFloat(r.distanceInMeters),
    }));
  }

  async getHandymanLocation(userId: string): Promise<GeoLocation | null> {
    const result = await this.usersRepository
      .createQueryBuilder('user')
      .select('ST_AsGeoJSON(user.location)::json as location')
      .where('user.id = :userId', { userId })
      .getRawOne();

    if (!result?.location) {
      return null;
    }

    return {
      latitude: result.location.coordinates[1],
      longitude: result.location.coordinates[0],
    };
  }
}
