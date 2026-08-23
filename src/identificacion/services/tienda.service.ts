import { Injectable, NotFoundException } from '@nestjs/common';
import { CreateTiendaDto } from '../dtos/create-tienda.dto';
import { Tienda } from '../repositories/entities/tienda.entity';
import { TiendaResponseDto } from '../dtos/tienda-response.dto';
import { TiendaRepository } from '../repositories/tienda.repository';
import { QueryTiendaDto } from '../dtos/query-tienda.dto';
import { UpdateTiendaDto } from '../dtos/update-tienda.dto';

@Injectable()
export class TiendaService {
    constructor(
        private readonly tiendaRepository: TiendaRepository
    ) {}

    async create(dto: CreateTiendaDto): Promise<TiendaResponseDto> {
        const tienda = await this.tiendaRepository.create(dto);
        return this.mapToResponse(tienda);
    }

    async findAll(query: QueryTiendaDto): Promise<TiendaResponseDto[]> {
        const tiendas = await this.tiendaRepository.findAll(query);
        return tiendas.map(tienda => this.mapToResponse(tienda));
    }

    async findById(id: string): Promise<TiendaResponseDto> {
        const tienda = await this.tiendaRepository.findById(id);
        if (!tienda) {
            throw new NotFoundException(`Tienda con id ${id} no encontrada`);
        }
        return this.mapToResponse(tienda);
    }

    async update(id: string, dto: UpdateTiendaDto): Promise<TiendaResponseDto> {
        const tienda = await this.tiendaRepository.findById(id);
        if (!tienda) {
            throw new NotFoundException(`Tienda con id ${id} no encontrada`);
        }

        const updatedTienda = await this.tiendaRepository.update(id, dto);
        return this.mapToResponse(updatedTienda!);
    }

    async delete(id: string): Promise<void> {
        const tienda = await this.tiendaRepository.findById(id);
        if (!tienda) {
            throw new NotFoundException(`Tienda con id ${id} no encontrada`);
        }

        await this.tiendaRepository.delete(id);
    }

    private mapToResponse(tienda: Tienda): TiendaResponseDto {
        return {
            id: tienda.id,
            codigoInterno: tienda.codigoInterno,
            nombreComercial: tienda.nombreComercial,
            responsableId: tienda.responsableId,
            rut: tienda.rut,
            direccion: tienda.direccion,
            telefono: tienda.telefono,
            estadoCaptacion: tienda.estadoCaptacion,
            createdAt: tienda.createdAt,
            updatedAt: tienda.updatedAt
        };
    }
}
