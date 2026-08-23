import { DataSource } from 'typeorm';
import { Tienda } from './entities/tienda.entity';

export const repositoryProviders = [
  {
    provide: 'TIENDA_REPOSITORY',
    useFactory: (dataSource: DataSource) => dataSource.getRepository(Tienda),
    inject: ['DATA_SOURCE'],
  },
];