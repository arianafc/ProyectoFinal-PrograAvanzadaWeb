USE SIGEP_WEB
GO

TRUNCATE TABLE dbo.Estados

INSERT INTO dbo.Estados (Descripcion) VALUES ('Activo'), ('Inactivo'), ('En Proceso de Aplicacion'),
('Rechazada'), ('Asignada'), ('Aprobada'), ('Retirada'), ('Finalizada'), ('Rezagado'), ('Archivado'), ('En Curso'),
('Pendiente de Aprobacion')
GO

INSERT INTO dbo.Roles (Descripcion, IdEstado) VALUES ('Estudiante', 1), ('Coordinador', 1), ('Profesor', 1)
GO

INSERT INTO dbo.Secciones (Seccion, IdEstado) VALUES ('12-1', 1), ('12-2', 1), ('12-3', 1), ('12-4', 1), ('N/A', 1)

-- Insertar provincias
INSERT INTO Provincias (Nombre) VALUES 
('San José'),
('Alajuela'),
('Cartago'),
('Heredia'),
('Guanacaste'),
('Puntarenas'),
('Limón');



