import { IsEnum, IsOptional, IsUUID } from "class-validator";
import { EstadoCaptacion } from "../repositories/entities/estado-captacion.enum";

export class QueryTiendaDto {
    @IsOptional()
    @IsUUID()
    responsableId?: string;

    @IsOptional()
    @IsEnum(EstadoCaptacion)
    estadoCaptacion?: EstadoCaptacion;
}