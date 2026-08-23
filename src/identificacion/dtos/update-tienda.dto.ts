import { IsEnum, IsOptional, IsString, IsUUID, MaxLength } from "class-validator";
import { EstadoCaptacion } from "../repositories/entities/estado-captacion.enum";

export class UpdateTiendaDto {
    @IsOptional()
    @IsUUID()
    responsableId?: string;

    @IsOptional()
    @IsString()
    @MaxLength(255)
    codigoInterno?: string;

    @IsOptional()
    @IsString()
    @MaxLength(255)
    nombreComercial?: string;

    @IsOptional()
    @IsString()
    @MaxLength(255)
    rut?: string;

    @IsOptional()
    @IsString()
    @MaxLength(255)
    direccion?: string;

    @IsOptional()
    @IsString()
    @MaxLength(255)
    telefono?: string;

    @IsOptional()
    @IsEnum(EstadoCaptacion)
    estadoCaptacion?: EstadoCaptacion;
}