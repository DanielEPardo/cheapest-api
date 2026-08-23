import { Module } from '@nestjs/common';
import { DatabaseModule } from 'src/datasources/database.module';
import { TiendaService } from './services/tienda.service';
import { TiendaRepository } from './repositories/tienda.repository';
import { repositoryProviders } from './repositories/repository.providers';
import { TiendaController } from './controllers/tienda.controller';

@Module({
    imports: [DatabaseModule],
    controllers: [
        TiendaController
    ],
    providers: [
        ...repositoryProviders,
        TiendaRepository, 
        TiendaService],
    exports: [TiendaService],
})
export class IdentificacionModule {}
