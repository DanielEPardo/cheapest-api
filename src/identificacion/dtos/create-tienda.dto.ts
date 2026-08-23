import { IsEnum, IsString, IsUUID, MaxLength } from "class-validator";
import { EstadoCaptacion } from "../repositories/entities/estado-captacion.enum";

export class CreateTiendaDto {
    @IsUUID()
    responsableId: string;

    @IsString()
    @MaxLength(255)
    codigoInterno: string;

    @IsString()
    @MaxLength(255)
    nombreComercial: string;

    @IsString()
    @MaxLength(255)
    rut: string;

    @IsString()
    @MaxLength(255)
    direccion: string;

    @IsString()
    @MaxLength(255)
    telefono: string;

    @IsEnum(EstadoCaptacion)
    estadoCaptacion: EstadoCaptacion;
}