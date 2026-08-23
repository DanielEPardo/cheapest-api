import { EstadoCaptacion } from "../repositories/entities/estado-captacion.enum";

export class TiendaResponseDto {
    id: string;
    codigoInterno: string;
    nombreComercial: string;
    responsableId: string;
    rut: string;
    direccion: string;
    telefono: string;
    estadoCaptacion: EstadoCaptacion;
    createdAt: Date;
    updatedAt: Date;
}