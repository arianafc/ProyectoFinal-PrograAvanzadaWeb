USE SIGEP_WEB;
GO

-- Especialidades
INSERT INTO Especialidades (Nombre, IdEstado)
VALUES
('N/A', 1),
('Redes y Telecomunicaciones', 1),
('Desarrollo de Software', 1),
('Ciberseguridad', 1),
('Bases de Datos', 1),
('Tecnología en Producción', 1),
('Soporte Técnico', 1);
GO

--EMPRESAS-- NO SE PUDO CORRER
USE SIGEP_WEB;
GO
INSERT INTO Empresas (NombreEmpresa, IdEstado, NombreContacto, IdDireccion, AreasAfinidad)
VALUES
('Intel Costa Rica', 1, 'María Morales', 1, 'Software'),
('Amazon Web Services', 1, 'Carlos Porras', 1, 'Cloud'),
('Banco Nacional', 1, 'Fernanda Jiménez', 1, 'Fintech'),
('ICE Tecnología', 1, 'Luis Rojas', 1, 'Redes'),
('Cooperativa Dos Pinos', 1, 'Ana López', 1, 'Administración');
GO

--MODALIDADES
USE SIGEP_WEB;
GO

INSERT INTO Modalidades (Descripcion)
VALUES
('Presencial'),
('Virtual'),
('Híbrida');
GO

--VACANTES-- NO SE PUDO CORRER
USE SIGEP_WEB;
GO

INSERT INTO VacantesPractica 
(Nombre, IdEstado, IdEmpresa, Requisitos, FechaMaxAplicacion, NumeroCupos, FechaCierre, IdModalidad, Descripcion, Tipo)
VALUES
('Práctica en Desarrollo Web', 1, 1, 'HTML, CSS, JS', '2025-11-30', 3, '2025-12-05', 1, 'Frontend básico', 'Técnica'),
('Soporte Técnico Nivel 1', 1, 5, 'Conocimientos básicos de hardware', '2025-11-28', 5, '2025-12-03', 3, 'Mesa de ayuda', 'Técnica'),
('Asistente de Redes', 1, 4, 'Networking básico', '2025-11-25', 2, '2025-12-01', 1, 'Redes y cableado', 'Técnica'),
('Analista de Datos Junior', 1, 3, 'SQL básico', '2025-11-28', 4, '2025-12-03', 2, 'Soporte analítico', 'Técnica'),
('Ciberseguridad SOC Nivel 1', 1, 2, 'Conocimientos de SIEM', '2025-11-26', 2, '2025-12-02', 3, 'Monitoreo de ciberseguridad', 'Técnica');
GO

--ASIGNAR ESPECIIALIDES
-- Desarrollo Web
INSERT INTO EspecialidadesVacante VALUES (1, 3);

-- Soporte Técnico
INSERT INTO EspecialidadesVacante VALUES (2, 7);

-- Redes
INSERT INTO EspecialidadesVacante VALUES (3, 2);

-- Bases de Datos
INSERT INTO EspecialidadesVacante VALUES (4, 4);

-- Ciberseguridad
INSERT INTO EspecialidadesVacante VALUES (5, 5);
GO

--USUARIOS
USE SIGEP_WEB;
GO

INSERT INTO Usuarios
(Cedula, Nombre, Apellido1, Apellido2, Contrasenna, FechaRegistro, Sexo, Nacionalidad, IdEstado, IdRol)
VALUES
('101010101', 'Carlos', 'Soto', 'Jiménez', '1234', GETDATE(), 'Masculino', 'Costarricense', 1, 1),
('202020202', 'María', 'Gómez', 'Castro', '1234', GETDATE(), 'Femenino', 'Costarricense', 1, 1),
('303030303', 'Luis', 'Arias', 'Monge', '1234', GETDATE(), 'Masculino', 'Costarricense', 1, 1),
('404040404', 'Ana', 'Lopez', 'Pérez', '1234', GETDATE(), 'Femenino', 'Costarricense', 1, 1),
('505050505', 'Jorge', 'Rojas', 'Mora', '1234', GETDATE(), 'Masculino', 'Costarricense', 1, 1),
('606060606', 'Valeria', 'Campos', 'Soto', '1234', GETDATE(), 'Femenino', 'Costarricense', 1, 1);
GO

--RELACIONAR USUARIO CON ESPECIALIDAD
USE SIGEP_WEB;
GO

-- Carlos ? Desarrollo Software
INSERT INTO UsuarioEspecialidad VALUES (3, 1, 1);

-- María ? Bases de Datos
INSERT INTO UsuarioEspecialidad VALUES (4, 2, 1);

-- Luis ? Redes
INSERT INTO UsuarioEspecialidad VALUES (2, 3, 1);

-- Ana ? Ciberseguridad
INSERT INTO UsuarioEspecialidad VALUES (5, 4, 1);

-- Jorge ? Soporte Técnico
INSERT INTO UsuarioEspecialidad VALUES (7, 5, 1);

-- Valeria ? N/A
INSERT INTO UsuarioEspecialidad VALUES (1, 6, 1);
GO

--INSERTAR PRACTICAS--- NO SE PUDO CORRER
USE SIGEP_WEB;
GO

INSERT INTO PracticaEstudiante (IdVacante, IdEstado, IdUsuario, FechaAplicacion)
VALUES
(1, 3, 1, '2025-11-10'),  -- Carlos ? Desarrollo Web
(1, 5, 2, '2025-11-12'),  -- María ? Asignada
(3, 11, 3, '2025-11-08'), -- Luis ? En curso
(5, 3, 4, '2025-11-11'),  -- Ana ? Proceso aplicación
(2, 7, 5, '2025-11-09'),  -- Jorge ? Retirada
(4, 5, 6, '2025-11-13');  -- Valeria ? Asignada
GO