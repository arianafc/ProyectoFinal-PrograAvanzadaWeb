-- Módulo de evaluación

USE SIGEP_WEB
GO

CREATE OR ALTER PROCEDURE [dbo].[ObtenerEstudiantesParaEvaluacionSP]
    @IdCoordinador INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @IdRol INT;
    SELECT @IdRol = IdRol FROM Usuarios WHERE IdUsuario = @IdCoordinador;
    
    IF @IdRol <> 2
    BEGIN
        RAISERROR('Solo los coordinadores pueden acceder a las evaluaciones.', 16, 1);
        RETURN;
    END
    
    SELECT 
        u.IdUsuario,
        u.Cedula,
        u.Nombre + ' ' + u.Apellido1 + ' ' + ISNULL(u.Apellido2, '') AS NombreCompleto,
        e.Nombre AS Especialidad,
        t.Telefono,
        v.Nombre AS PracticaAsignada,
        CASE 
            WHEN n.NotaFinal >= 70 THEN 'Aprobado'
            WHEN n.NotaFinal < 70 AND n.NotaFinal IS NOT NULL THEN 'Rezagado'
            ELSE 'Aprobado'
        END AS EstadoAcademico,
        ISNULL(CAST(n.NotaFinal AS DECIMAL(5,2)), 0.00) AS NotaFinal,
        p.IdPractica,
        p.IdVacante
    FROM Usuarios u
    INNER JOIN UsuarioEspecialidad ue ON u.IdUsuario = ue.IdUsuario AND ue.IdEstado = 1
    INNER JOIN Especialidades e ON ue.IdEspecialidad = e.IdEspecialidad
    LEFT JOIN Telefonos t ON u.IdUsuario = t.IdUsuario
    INNER JOIN PracticaEstudiante p ON u.IdUsuario = p.IdUsuario
    LEFT JOIN VacantesPractica v ON p.IdVacante = v.IdVacantePractica
    LEFT JOIN NotasEstudiantes n ON u.IdUsuario = n.IdUsuario
    INNER JOIN Estados est ON p.IdEstado = est.IdEstado
    WHERE u.IdRol = 1  
        AND u.IdEstado = 1 
        AND est.Descripcion IN ('En Curso', 'Rezagado', 'Aprobada', 'Finalizada')
    ORDER BY u.Nombre, u.Apellido1;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[ObtenerPerfilEstudianteSP]
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        u.IdUsuario,
        u.Cedula,
        u.Nombre + ' ' + u.Apellido1 + ' ' + ISNULL(u.Apellido2, '') AS NombreCompleto,
        u.Nombre,
        u.Apellido1,
        u.Apellido2,
        em.Email AS Correo,
        t.Telefono,
        ISNULL(d.DireccionExacta, '') + 
        CASE WHEN d.DireccionExacta IS NOT NULL THEN ', ' ELSE '' END +
        ISNULL(dis.Nombre, '') + 
        CASE WHEN dis.Nombre IS NOT NULL THEN ', ' ELSE '' END +
        ISNULL(c.Nombre, '') + 
        CASE WHEN c.Nombre IS NOT NULL THEN ', ' ELSE '' END +
        ISNULL(p.Nombre, '') AS Direccion,
        CASE 
            WHEN u.Sexo = 'M' THEN 'Masculino' 
            WHEN u.Sexo = 'F' THEN 'Femenino' 
            ELSE u.Sexo 
        END AS Sexo,
        e.Nombre AS Especialidad,
        DATEDIFF(YEAR, u.FechaNacimiento, GETDATE()) - 
        CASE 
            WHEN MONTH(u.FechaNacimiento) > MONTH(GETDATE()) 
                OR (MONTH(u.FechaNacimiento) = MONTH(GETDATE()) AND DAY(u.FechaNacimiento) > DAY(GETDATE()))
            THEN 1 
            ELSE 0 
        END AS Edad,
        s.Seccion,
        emp.NombreEmpresa,
        temp.Telefono AS TelefonoEmpresa,
        pr.IdVacante,
        pr.IdUsuario AS IdEstudiante,
        pr.IdPractica
    FROM Usuarios u
    LEFT JOIN Emails em ON u.IdUsuario = em.IdUsuario
    LEFT JOIN Telefonos t ON u.IdUsuario = t.IdUsuario
    LEFT JOIN Direcciones d ON u.IdDireccion = d.IdDireccion
    LEFT JOIN Distritos dis ON d.IdDistrito = dis.IdDistrito
    LEFT JOIN Cantones c ON dis.IdCanton = c.IdCanton
    LEFT JOIN Provincias p ON c.IdProvincia = p.IdProvincia
    LEFT JOIN UsuarioEspecialidad ue ON u.IdUsuario = ue.IdUsuario AND ue.IdEstado = 1
    LEFT JOIN Especialidades e ON ue.IdEspecialidad = e.IdEspecialidad
    LEFT JOIN Secciones s ON u.IdSeccion = s.IdSeccion
    LEFT JOIN PracticaEstudiante pr ON u.IdUsuario = pr.IdUsuario 
        AND pr.IdEstado = (SELECT IdEstado FROM Estados WHERE Descripcion = 'En Curso')
    LEFT JOIN VacantesPractica v ON pr.IdVacante = v.IdVacantePractica
    LEFT JOIN Empresas emp ON v.IdEmpresa = emp.IdEmpresa
    LEFT JOIN Telefonos temp ON emp.IdEmpresa = temp.IdEmpresa
    WHERE u.IdUsuario = @IdUsuario;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[ObtenerComentariosEstudianteSP]
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        c.IdComentario,
        u.Nombre + ' ' + u.Apellido1 AS Autor,
        CONVERT(VARCHAR(10), c.Fecha, 103) AS FechaFormateada,
        c.Fecha,
        c.Comentario,
        c.Tipo
    FROM ComentariosPractica c
    INNER JOIN PracticaEstudiante p ON c.IdPractica = p.IdPractica
    INNER JOIN Usuarios u ON c.IdUsuario = u.IdUsuario
    WHERE p.IdUsuario = @IdUsuario
        AND (
            LTRIM(RTRIM(c.Tipo)) = 'Evaluación Tutor' 
            OR LTRIM(RTRIM(c.Tipo)) = 'Actualización Estado'
        )
    ORDER BY c.Fecha DESC, c.IdComentario DESC; 
END
GO

CREATE OR ALTER PROCEDURE [dbo].[ObtenerNotasEstudianteSP]
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        ISNULL(Nota1, 0.00) AS Nota1,
        ISNULL(Nota2, 0.00) AS Nota2,
        ISNULL(NotaFinal, 0.00) AS NotaFinal
    FROM NotasEstudiantes
    WHERE IdUsuario = @IdUsuario;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[GuardarNotaEstudianteSP]
    @IdUsuario INT,
    @Nota1 DECIMAL(5,2),
    @Nota2 DECIMAL(5,2),
    @NotaFinal DECIMAL(5,2),
    @IdCoordinador INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @IdRol INT;
        SELECT @IdRol = IdRol FROM Usuarios WHERE IdUsuario = @IdCoordinador;
        
        IF @IdRol <> 2
        BEGIN
            RAISERROR('Solo los coordinadores pueden asignar notas.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        IF EXISTS (SELECT 1 FROM NotasEstudiantes WHERE IdUsuario = @IdUsuario)
        BEGIN
            UPDATE NotasEstudiantes
            SET Nota1 = @Nota1,
                Nota2 = @Nota2,
                NotaFinal = @NotaFinal,
                FechaActualizacion = GETDATE(),
                IdCoordinador = @IdCoordinador
            WHERE IdUsuario = @IdUsuario;
        END
        ELSE
        BEGIN
            INSERT INTO NotasEstudiantes (IdUsuario, Nota1, Nota2, NotaFinal, FechaRegistro, IdCoordinador)
            VALUES (@IdUsuario, @Nota1, @Nota2, @NotaFinal, GETDATE(), @IdCoordinador);
        END
        
        COMMIT TRANSACTION;
        
        SELECT 1 AS Exito, 'Nota registrada correctamente' AS Mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SELECT 0 AS Exito, ERROR_MESSAGE() AS Mensaje;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE [dbo].[GuardarComentarioEvaluacionSP]
    @IdUsuario INT,
    @IdCoordinador INT,
    @Comentario VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @IdRol INT;
        SELECT @IdRol = IdRol FROM Usuarios WHERE IdUsuario = @IdCoordinador;
        
        IF @IdRol <> 2
        BEGIN
            RAISERROR('Solo los coordinadores pueden agregar comentarios de evaluación.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        DECLARE @IdPractica INT;
        SELECT TOP 1 @IdPractica = IdPractica 
        FROM PracticaEstudiante 
        WHERE IdUsuario = @IdUsuario 
            AND IdEstado = (SELECT IdEstado FROM Estados WHERE Descripcion = 'En Curso');
        
        IF @IdPractica IS NULL
        BEGIN
            RAISERROR('El estudiante no tiene una práctica activa.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        INSERT INTO ComentariosPractica (Comentario, Fecha, IdUsuario, IdPractica, Tipo)
        VALUES (@Comentario, GETDATE(), @IdCoordinador, @IdPractica, 'Evaluación Tutor');
        
        COMMIT TRANSACTION;
        
        SELECT 1 AS Exito, 'Comentario guardado correctamente' AS Mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SELECT 0 AS Exito, ERROR_MESSAGE() AS Mensaje;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE [dbo].[ObtenerDocumentosEvaluacionSP]
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        IdDocumento,
        Documento AS NombreArchivo,
        Tipo,
        FechaSubida,
        LOWER(RIGHT(Documento, CHARINDEX('.', REVERSE(Documento)) - 1)) AS Extension
    FROM Documentos
    WHERE IdUsuario = @IdUsuario 
        AND Tipo = 'Evaluación'
    ORDER BY FechaSubida DESC;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[GuardarDocumentoEvaluacionSP]
    @IdUsuario INT,
    @NombreArchivo VARCHAR(255),
    @Tipo VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        INSERT INTO Documentos (Documento, Tipo, IdUsuario, FechaSubida)
        VALUES (@NombreArchivo, @Tipo, @IdUsuario, GETDATE());
        
        DECLARE @IdDocumento INT = SCOPE_IDENTITY();
        
        COMMIT TRANSACTION;
        
        SELECT 1 AS Exito, 'Documento guardado correctamente' AS Mensaje, @IdDocumento AS IdDocumento;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SELECT 0 AS Exito, ERROR_MESSAGE() AS Mensaje, NULL AS IdDocumento;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE [dbo].[ObtenerNombreCompletoUsuarioSP]
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        Nombre + ' ' + Apellido1 AS NombreCompleto
    FROM Usuarios
    WHERE IdUsuario = @IdUsuario;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[ObtenerCedulaUsuarioSP]
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        Cedula
    FROM Usuarios
    WHERE IdUsuario = @IdUsuario;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[ObtenerDocumentoPorIdSP]
    @IdDocumento INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        IdDocumento,
        Documento,
        IdUsuario
    FROM Documentos
    WHERE IdDocumento = @IdDocumento;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[EliminarDocumentoSP]
    @IdDocumento INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        DELETE FROM Documentos 
        WHERE IdDocumento = @IdDocumento;
        
        IF @@ROWCOUNT > 0
            SELECT 1 AS Exito, 'Documento eliminado correctamente' AS Mensaje;
        ELSE
            SELECT 0 AS Exito, 'No se pudo eliminar el documento' AS Mensaje;
    END TRY
    BEGIN CATCH
        SELECT 0 AS Exito, ERROR_MESSAGE() AS Mensaje;
    END CATCH
END
GO

-- Crear tabla para almacenar las notas de los estudiantes
CREATE TABLE [dbo].[NotasEstudiantes](
    [IdNota] [int] IDENTITY(1,1) NOT NULL,
    [IdUsuario] [int] NOT NULL,
    [Nota1] [decimal](5, 2) NULL,
    [Nota2] [decimal](5, 2) NULL,
    [NotaFinal] [decimal](5, 2) NULL,
    [FechaRegistro] [datetime] NOT NULL DEFAULT GETDATE(),
    [FechaActualizacion] [datetime] NULL,
    [IdCoordinador] [int] NOT NULL,
    CONSTRAINT [PK_NotasEstudiantes] PRIMARY KEY CLUSTERED ([IdNota] ASC),
    CONSTRAINT [FK_NotasEstudiantes_Usuario] FOREIGN KEY([IdUsuario]) REFERENCES [dbo].[Usuarios] ([IdUsuario]),
    CONSTRAINT [FK_NotasEstudiantes_Coordinador] FOREIGN KEY([IdCoordinador]) REFERENCES [dbo].[Usuarios] ([IdUsuario])
)
GO

-- Stored Procedure principal para obtener todos los datos
CREATE OR ALTER PROCEDURE [dbo].[ObtenerVisualizacionPracticaSP]
    @IdVacante INT,
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        -- Datos de la Vacante
        v.IdVacantePractica,
        v.Nombre,
        e.NombreEmpresa as EmpresaNombre,
        v.Requisitos as Requerimientos,
        v.FechaMaxAplicacion,
        ISNULL(m.Descripcion, v.IdModalidad) as ModalidadNombre,
        
        -- Datos del Estudiante
        u.IdUsuario,
        CONCAT(u.Nombre, ' ', u.Apellido1, ' ', u.Apellido2) as EstudianteNombre,
        u.Cedula as EstudianteCedula,
        DATEDIFF(YEAR, u.FechaNacimiento, GETDATE()) as EstudianteEdad,
        esp.Nombre as EstudianteEspecialidad,
        eu.Email as EstudianteCorreo,
        
        -- Datos de Contacto Empresa
        e.NombreContacto as ContactoEmpresaNombre,
        ee.Email as ContactoEmpresaEmail,
        te.Telefono as ContactoEmpresaTelefono,
        
        -- Datos de la Práctica
        p.IdPractica,
        p.FechaAplicacion,
        est.Descripcion as EstadoPractica,
        
        -- Notas
        n.Nota1,
        n.Nota2,
        n.NotaFinal
        
    FROM VacantesPractica v
    INNER JOIN Empresas e ON v.IdEmpresa = e.IdEmpresa
    LEFT JOIN Modalidades m ON v.IdModalidad = m.IdModalidad
    INNER JOIN PracticaEstudiante p ON v.IdVacantePractica = p.IdVacante AND p.IdUsuario = @IdUsuario
    INNER JOIN Usuarios u ON p.IdUsuario = u.IdUsuario
    INNER JOIN Estados est ON p.IdEstado = est.IdEstado
    LEFT JOIN UsuarioEspecialidad ue ON u.IdUsuario = ue.IdUsuario AND ue.IdEstado = 1
    LEFT JOIN Especialidades esp ON ue.IdEspecialidad = esp.IdEspecialidad
    LEFT JOIN Emails eu ON u.IdUsuario = eu.IdUsuario
    LEFT JOIN Emails ee ON e.IdEmpresa = ee.IdEmpresa  
    LEFT JOIN Telefonos te ON e.IdEmpresa = te.IdEmpresa
    LEFT JOIN NotasEstudiantes n ON u.IdUsuario = n.IdUsuario
    WHERE v.IdVacantePractica = @IdVacante
END
GO

-- Stored Procedure para obtener comentarios
CREATE OR ALTER PROCEDURE [dbo].[ObtenerComentariosPracticaSP]
    @IdVacante INT,
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        c.IdComentario as Id,
        c.Fecha,
        CONCAT(u.Nombre, ' ', u.Apellido1) as Usuario,
        c.Comentario
    FROM ComentariosPractica c
    INNER JOIN Usuarios u ON c.IdUsuario = u.IdUsuario
    INNER JOIN PracticaEstudiante p ON c.IdPractica = p.IdPractica
    WHERE p.IdVacante = @IdVacante AND p.IdUsuario = @IdUsuario
    ORDER BY c.Fecha DESC, c.IdComentario DESC;
END
GO

-- Stored Procedure para insertar comentarios
CREATE OR ALTER PROCEDURE [dbo].[InsertarComentarioPracticaSP]
    @IdVacante INT,
    @IdUsuario INT,
    @Comentario VARCHAR(1000),
    @IdUsuarioComentario INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @IdPractica INT;
    DECLARE @FilasAfectadas INT = 0;
    
    -- Obtener el IdPractica
    SELECT @IdPractica = IdPractica 
    FROM PracticaEstudiante 
    WHERE IdVacante = @IdVacante AND IdUsuario = @IdUsuario;
    
    IF @IdPractica IS NOT NULL
    BEGIN
        INSERT INTO ComentariosPractica 
        (Comentario, Fecha, IdUsuario, IdPractica, Tipo)
        VALUES 
        (@Comentario, GETDATE(), @IdUsuarioComentario, @IdPractica, 'General');
        
        SET @FilasAfectadas = @@ROWCOUNT;
    END
    
    -- Devolver el número de filas afectadas
    SELECT @FilasAfectadas as FilasAfectadas;
END
GO

-- Stored Procedure para actualizar estado de la practica
CREATE OR ALTER PROCEDURE ActualizarEstadoPracticaSP
    @IdPractica INT,
    @IdEstado INT,
    @Comentario NVARCHAR(MAX),
    @IdUsuarioSesion INT 
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- 1. Actualizar estado de la práctica
        UPDATE PracticaEstudiante
        SET IdEstado = @IdEstado
        WHERE IdPractica = @IdPractica;
        
        -- 2. Insertar comentario si se proporcionó
        DECLARE @IdComentarioNuevo INT = NULL;
        
        IF @Comentario IS NOT NULL AND LTRIM(RTRIM(@Comentario)) <> ''
        BEGIN
            -- Usar @IdUsuarioSesion en lugar de p.IdUsuario
            INSERT INTO ComentariosPractica (Comentario, Fecha, IdUsuario, IdPractica, Tipo)
            VALUES (@Comentario, GETDATE(), @IdUsuarioSesion, @IdPractica, 'Actualización Estado');
            
            -- Capturar el ID del comentario recién insertado
            SET @IdComentarioNuevo = SCOPE_IDENTITY();
        END
        
        -- 3. Devolver información relevante
        SELECT 
            p.IdPractica,
            p.IdVacante,
            p.IdUsuario,
            u.Nombre + ' ' + u.Apellido1 + ' ' + ISNULL(u.Apellido2, '') AS EstudianteNombre,
            e.Email AS EstudianteCorreo,
            es.Descripcion AS EstadoDescripcion,
            c.Comentario,
            c.Fecha AS FechaComentario
        FROM PracticaEstudiante p
        INNER JOIN Usuarios u ON p.IdUsuario = u.IdUsuario
        LEFT JOIN Emails e ON u.IdUsuario = e.IdUsuario
        INNER JOIN Estados es ON p.IdEstado = es.IdEstado
        -- Usar el comentario específico que acabamos de insertar
        LEFT JOIN ComentariosPractica c ON c.IdComentario = @IdComentarioNuevo
        WHERE p.IdPractica = @IdPractica;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE [dbo].[ObtenerEstadosPracticaSP]
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Lista de estados permitidos para las prácticas
    SELECT 
        IdEstado,
        Descripcion
    FROM Estados
    WHERE Descripcion IN (
        'En Proceso de Aplicacion',
        'Rechazado',
        'Asignada',
        'Retirada',
        'En Curso'
    )
    ORDER BY Descripcion;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[VerificarEstadoAcademicoEstudianteSP]
    @IdPractica INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        u.IdUsuario
    FROM PracticaEstudiante p
    INNER JOIN Usuarios u ON p.IdUsuario = u.IdUsuario
    WHERE p.IdPractica = @IdPractica;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[ObtenerDescripcionEstadoSP]
    @IdEstado INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT Descripcion 
    FROM Estados 
    WHERE IdEstado = @IdEstado;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[VerificarPracticasSP]
    @IdPractica INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT TOP 1 
        v.Nombre,
        e.Descripcion as Estado
    FROM PracticaEstudiante p
    INNER JOIN Estados e ON p.IdEstado = e.IdEstado
    LEFT JOIN VacantesPractica v ON p.IdVacante = v.IdVacantePractica
    WHERE p.IdUsuario = (SELECT IdUsuario FROM PracticaEstudiante WHERE IdPractica = @IdPractica)
        AND p.IdPractica != @IdPractica
        AND e.Descripcion IN ('Asignada', 'En Curso', 'Aprobada', 'Finalizada');
END
GO