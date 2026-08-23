import { Inject, Injectable } from "@nestjs/common";
import { Tienda } from "./entities/tienda.entity";
import { Repository } from "typeorm";
import { QueryTiendaDto } from "../dtos/query-tienda.dto";

@Injectable()
export class TiendaRepository {
    constructor(
        @Inject('TIENDA_REPOSITORY')
        private repository: Repository<Tienda>,
    ) {}

    async create(tienda: Partial<Tienda>): Promise<Tienda> {
        const newTienda = this.repository.create(tienda);
        return this.repository.save(newTienda);
    }

    async findAll(query: QueryTiendaDto): Promise<Tienda[]> {
        const queryBuilder = this.repository.createQueryBuilder('tienda');

        if (query.responsableId) {
            queryBuilder.andWhere('tienda.responsableId = :responsableId', {
                responsableId: query.responsableId
            });
        }

        if (query.estadoCaptacion) {
            queryBuilder.andWhere('tienda.estadoCaptacion = :estadoCaptacion', {
                estadoCaptacion: query.estadoCaptacion
            });
        }

        return queryBuilder.getMany();
    }

    async findById(id: string): Promise<Tienda | null> {
        return this.repository.findOne({ where: { id }});
    }

    async update(id: string, tienda: Partial<Tienda>): Promise<Tienda | null> {
        await this.repository.update(id, tienda);
        return this.findById(id);
    }

    async delete(id: string): Promise<boolean> {
        const result = await this.repository.delete(id);
        return (result.affected ?? 0) > 0;
    }    
}