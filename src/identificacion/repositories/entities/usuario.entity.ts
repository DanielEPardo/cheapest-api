import { Column, CreateDateColumn, Entity, JoinColumn, ManyToOne, PrimaryGeneratedColumn, UpdateDateColumn } from "typeorm";
import { Perfil } from "./perfil.enum";
import { Tienda } from "./tienda.entity";

@Entity('usuarios')
export class Usuario {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column('varchar', { length: 255 })
    nombre: string;

    @Column('varchar', { length: 255 })
    telefono: string;

    @Column({type: 'enum', enum: Perfil})
    perfil: Perfil;

    @Column('uuid')
    tiendaId: string;

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;

    @ManyToOne(() => Tienda, (tienda) => tienda.usuarios)
    @JoinColumn({ name: 'tiendaId' })
    tienda: Tienda;
}