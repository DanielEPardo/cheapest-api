import { Column, CreateDateColumn, Entity, JoinColumn, ManyToOne, OneToMany, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm";
import { Usuario } from "./usuario.entity";
import { EstadoCaptacion } from "./estado-captacion.enum";

@Entity('tiendas')
export class Tienda {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column('varchar', { length: 255 })
    codigoInterno: string;

    @Column('varchar', { length: 255 })
    nombreComercial: string;

    @Column('uuid')
    responsableId: string;

    @ManyToOne(() => Usuario)
    @JoinColumn({ name: 'responsableId' })
    responsable: Usuario;

    @OneToMany(() => Usuario, (usuario) => usuario.tienda)
    usuarios: Usuario[];

    @Column('varchar', { length: 255 })
    rut: string;

    @Column('varchar', { length: 255 })
    direccion: string;

    @Column('varchar', { length: 255 })
    telefono: string;

    @Column({ type: 'enum', enum: EstadoCaptacion })
    estadoCaptacion: EstadoCaptacion;

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;
}