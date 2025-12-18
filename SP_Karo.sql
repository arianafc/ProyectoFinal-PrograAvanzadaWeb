USE SIGEP_WEB;
GO

/* =========================================================
   Helpers: Obtener IdEstado por Descripción (función inline)
   ========================================================= */
CREATE OR ALTER FUNCTION dbo.fn_IdEstado (@desc NVARCHAR(100))
RETURNS INT
AS
BEGIN
    DECLARE @id INT;
    SELECT @id = IdEstado FROM Estados WHERE LTRIM(RTRIM(LOWER(Descripcion))) = LTRIM(RTRIM(LOWER(@desc)));
    RETURN @id;
END
GO

/* =========================================================
   GET: Listar Vacantes (para DataTable)
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.GetVacantesSP
    @IdEstado       INT = 0,
    @IdEspecialidad INT = 0,
    @IdModalidad    INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdE_Asig   INT;
    DECLARE @IdE_Curso  INT;
    DECLARE @IdE_Aprob  INT;
    DECLARE @IdE_Fin    INT;
    DECLARE @IdE_Rezag  INT;
    
    SELECT @IdE_Asig = IdEstado FROM Estados WHERE LOWER(LTRIM(RTRIM(Descripcion))) = 'asignada';
    SELECT @IdE_Curso = IdEstado FROM Estados WHERE LOWER(LTRIM(RTRIM(Descripcion))) = 'en curso';
    SELECT @IdE_Aprob = IdEstado FROM Estados WHERE LOWER(LTRIM(RTRIM(Descripcion))) = 'aprobada';
    SELECT @IdE_Fin = IdEstado FROM Estados WHERE LOWER(LTRIM(RTRIM(Descripcion))) = 'finalizada';
    SELECT @IdE_Rezag = IdEstado FROM Estados WHERE LOWER(LTRIM(RTRIM(Descripcion))) = 'rezagado';

    ;WITH Esp AS (
        SELECT ev.IdVacante,
               STRING_AGG(e.Nombre, ', ') AS EspecialidadNombre
        FROM EspecialidadesVacante ev
        INNER JOIN Especialidades e ON e.IdEspecialidad = ev.IdEspecialidad
        GROUP BY ev.IdVacante
    ),
    Post AS (
        SELECT p.IdVacante,
               COUNT(*) AS NumPostulados
        FROM PracticaEstudiante p
        WHERE p.IdEstado IN (@IdE_Asig, @IdE_Curso, @IdE_Aprob, @IdE_Fin, @IdE_Rezag)
        GROUP BY p.IdVacante
    )
    SELECT
        v.IdVacantePractica            AS IdVacante,
        v.Nombre                        AS Nombre,
        emp.IdEmpresa                   AS IdEmpresa,
        emp.NombreEmpresa              AS EmpresaNombre,
        ISNULL(esp.EspecialidadNombre, '—') AS EspecialidadNombre,
        v.Requisitos                   AS Requisitos,  -- ✅ CORREGIDO
        v.NumeroCupos                  AS NumCupos,
        ISNULL(po.NumPostulados, 0)    AS NumPostulados,
        est.Descripcion                AS EstadoNombre,
        v.IdModalidad                   AS IdModalidad,
        v.Descripcion                   AS Descripcion,
        v.FechaMaxAplicacion           AS FechaMaxAplicacion,
        v.FechaCierre                   AS FechaCierre,
        v.Tipo                          AS Tipo
    FROM VacantesPractica v
    INNER JOIN Empresas emp   ON emp.IdEmpresa = v.IdEmpresa
    INNER JOIN Estados est    ON est.IdEstado  = v.IdEstado
    LEFT  JOIN Esp esp        ON esp.IdVacante = v.IdVacantePractica
    LEFT  JOIN Post po        ON po.IdVacante  = v.IdVacantePractica
    WHERE (@IdEstado = 0 OR v.IdEstado = @IdEstado)
      AND (@IdEspecialidad = 0 OR EXISTS (
            SELECT 1 FROM EspecialidadesVacante ev
            WHERE ev.IdVacante = v.IdVacantePractica
              AND ev.IdEspecialidad = @IdEspecialidad
      ))
      AND (@IdModalidad = 0 OR v.IdModalidad = @IdModalidad)
    ORDER BY v.IdVacantePractica DESC;
END
GO

/* =========================================================
   GET: Detalle Vacante
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.DetalleVacanteSP
    @IdVacante INT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Esp AS (
        SELECT ev.IdVacante,
               STRING_AGG(e.Nombre, ', ') AS Especialidades,
               MIN(e.IdEspecialidad) AS IdEspecialidad
        FROM EspecialidadesVacante ev
        INNER JOIN Especialidades e ON e.IdEspecialidad = ev.IdEspecialidad
        WHERE ev.IdVacante = @IdVacante
        GROUP BY ev.IdVacante
    ),
    Ubi AS (
        SELECT
            emp.IdEmpresa,
            ISNULL(
                CONCAT(
                    ISNULL(p.Nombre, ''),
                    CASE WHEN p.Nombre IS NOT NULL AND c.Nombre IS NOT NULL THEN ', ' ELSE '' END,
                    ISNULL(c.Nombre, ''),
                    CASE WHEN c.Nombre IS NOT NULL AND d.Nombre IS NOT NULL THEN ', ' ELSE '' END,
                    ISNULL(d.Nombre, ''),
                    CASE WHEN d.Nombre IS NOT NULL AND dir.DireccionExacta IS NOT NULL THEN '. ' ELSE '' END,
                    ISNULL(dir.DireccionExacta, '')
                ),
                'No registrada'
            ) AS Ubicacion
        FROM Empresas emp
        LEFT JOIN Direcciones dir ON dir.IdDireccion = emp.IdDireccion
        LEFT JOIN Distritos d     ON d.IdDistrito    = dir.IdDistrito
        LEFT JOIN Cantones c      ON c.IdCanton      = d.IdCanton
        LEFT JOIN Provincias p    ON p.IdProvincia   = c.IdProvincia
        WHERE emp.IdEmpresa = (SELECT IdEmpresa FROM VacantesPractica WHERE IdVacantePractica = @IdVacante)
    )
    SELECT
        v.IdVacantePractica AS IdVacante,
        v.Nombre,
        v.IdEmpresa,
        emp.NombreEmpresa AS EmpresaNombre,
        ISNULL(esp.IdEspecialidad, 0) AS IdEspecialidad,
        v.IdModalidad,
        v.Descripcion,
        v.Requisitos AS Requisitos, 
        v.NumeroCupos AS NumCupos,
        v.FechaMaxAplicacion,
        v.FechaCierre,
        v.Tipo,
        e.Descripcion AS EstadoNombre,
        ISNULL(esp.Especialidades,'—') AS Especialidades,
        ISNULL(u.Ubicacion,'No registrada') AS Ubicacion
    FROM VacantesPractica v
    INNER JOIN Empresas emp ON emp.IdEmpresa = v.IdEmpresa
    INNER JOIN Estados e    ON e.IdEstado  = v.IdEstado
    LEFT  JOIN Esp esp      ON esp.IdVacante = v.IdVacantePractica
    LEFT  JOIN Ubi u        ON u.IdEmpresa = v.IdEmpresa
    WHERE v.IdVacantePractica = @IdVacante;
END
GO

/* =========================================================
   GET: Postulaciones por Vacante
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.ObtenerPostulacionesSP
    @IdVacante INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.IdPractica,
        p.IdVacante,
        u.IdUsuario,
        u.Cedula,
        NombreCompleto = CONCAT(u.Nombre,' ',u.Apellido1,' ',u.Apellido2),
        EstadoDescripcion = e.Descripcion
    FROM PracticaEstudiante p
    INNER JOIN Usuarios u ON u.IdUsuario = p.IdUsuario
    INNER JOIN Estados  e ON e.IdEstado  = p.IdEstado
    WHERE p.IdVacante = @IdVacante
    ORDER BY p.IdPractica DESC;
END
GO

/* =========================================================
   GET: Visualización de una Postulación (vacante + usuario)
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.VisualizacionPostulacionSP
    @IdVacante INT,
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        p.IdPractica,
        p.IdVacante,
        p.IdUsuario,
        EstadoDescripcion = e.Descripcion,
        NombreCompleto = CONCAT(u.Nombre,' ',u.Apellido1,' ',u.Apellido2)
    FROM PracticaEstudiante p
    INNER JOIN Estados e ON e.IdEstado = p.IdEstado
    INNER JOIN Usuarios u ON u.IdUsuario = p.IdUsuario
    WHERE p.IdVacante = @IdVacante AND p.IdUsuario = @IdUsuario
    ORDER BY p.IdPractica DESC;
END
GO

/* =========================================================
   GET: Estudiantes para Asignar 
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.ObtenerEstudiantesAsignarSP
    @IdVacante INT,
    @IdUsuarioSesion INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdRolEst INT; 
    SELECT @IdRolEst = IdRol FROM Roles WHERE LOWER(LTRIM(RTRIM(Descripcion)))='estudiante';

    DECLARE @IdE_Activo INT = dbo.fn_IdEstado('Activo');

    DECLARE @Req TABLE (IdEspecialidad INT);
    INSERT INTO @Req(IdEspecialidad)
    SELECT IdEspecialidad FROM EspecialidadesVacante WHERE IdVacante = @IdVacante;

    ;WITH EstEsp AS (
        SELECT ue.IdUsuario,
               STRING_AGG(e.Nombre, ', ') WITHIN GROUP (ORDER BY e.Nombre) AS Especialidad
        FROM UsuarioEspecialidad ue
        INNER JOIN Especialidades e ON e.IdEspecialidad = ue.IdEspecialidad
        WHERE ue.IdEstado = @IdE_Activo
        GROUP BY ue.IdUsuario
    ),
    UltimoEstado AS (
        SELECT p.IdUsuario,
               MAX(p.IdPractica) AS IdPracticaUlt
        FROM PracticaEstudiante p
        GROUP BY p.IdUsuario
    )
    SELECT
        u.IdUsuario,
        u.Cedula,
        NombreCompleto = CONCAT(u.Nombre,' ',u.Apellido1,' ',u.Apellido2),
        ISNULL(es.Especialidad,'—') AS Especialidad,
        EstadoAcademico = CASE WHEN u.IdEstado = @IdE_Activo THEN 1 ELSE 0 END,
        EstadoPractica = ISNULL((
            SELECT TOP 1 e1.Descripcion
            FROM PracticaEstudiante p1
            INNER JOIN Estados e1 ON e1.IdEstado = p1.IdEstado
            WHERE p1.IdUsuario = u.IdUsuario
            ORDER BY p1.IdPractica DESC
        ), 'Sin proceso activo'),
        EstadoVacante = ISNULL((
            SELECT TOP 1 e2.Descripcion
            FROM PracticaEstudiante p2
            INNER JOIN Estados e2 ON e2.IdEstado = p2.IdEstado
            WHERE p2.IdUsuario = u.IdUsuario AND p2.IdVacante = @IdVacante
            ORDER BY p2.IdPractica DESC
        ), 'Sin proceso activo'),
        IdPracticaVacante = ISNULL((
            SELECT TOP 1 p3.IdPractica
            FROM PracticaEstudiante p3
            WHERE p3.IdUsuario = u.IdUsuario AND p3.IdVacante = @IdVacante
            ORDER BY p3.IdPractica DESC
        ), 0)
    FROM Usuarios u
    LEFT JOIN EstEsp es ON es.IdUsuario = u.IdUsuario
    WHERE u.IdRol = @IdRolEst
      AND u.IdEstado = @IdE_Activo
      AND EXISTS (
            SELECT 1
            FROM UsuarioEspecialidad ue
            WHERE ue.IdUsuario = u.IdUsuario
              AND ue.IdEstado = @IdE_Activo
              AND ue.IdEspecialidad IN (SELECT IdEspecialidad FROM @Req)
      )
    ORDER BY NombreCompleto;
END
GO

/* =========================================================
   SP: Obtener Ubicación de Empresa
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.ObtenerUbicacionEmpresaSP
    @IdEmpresa INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        ISNULL(
            CONCAT(
                ISNULL(p.Nombre, ''),
                CASE WHEN p.Nombre IS NOT NULL AND c.Nombre IS NOT NULL THEN ', ' ELSE '' END,
                ISNULL(c.Nombre, ''),
                CASE WHEN c.Nombre IS NOT NULL AND d.Nombre IS NOT NULL THEN ', ' ELSE '' END,
                ISNULL(d.Nombre, ''),
                CASE WHEN d.Nombre IS NOT NULL AND dir.DireccionExacta IS NOT NULL THEN '. ' ELSE '' END,
                ISNULL(dir.DireccionExacta, '')
            ),
            'No registrada'
        ) AS Ubicacion
    FROM Empresas emp
    LEFT JOIN Direcciones dir ON dir.IdDireccion = emp.IdDireccion
    LEFT JOIN Distritos d     ON d.IdDistrito    = dir.IdDistrito
    LEFT JOIN Cantones c      ON c.IdCanton      = d.IdCanton
    LEFT JOIN Provincias p    ON p.IdProvincia   = c.IdProvincia
    WHERE emp.IdEmpresa = @IdEmpresa;
END
GO

/* =========================================================
   POST: Crear Vacante
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.CrearVacanteSP
    @Nombre NVARCHAR(255),
    @IdEmpresa INT,
    @IdEspecialidad INT,
    @NumCupos INT,
    @IdModalidad INT,
    @Requisitos NVARCHAR(MAX), 
    @Descripcion NVARCHAR(255),
    @FechaMaxAplicacion DATE,
    @FechaCierre DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdEstadoActivo INT;
    SELECT TOP 1 @IdEstadoActivo = IdEstado 
    FROM Estados 
    WHERE LOWER(LTRIM(RTRIM(Descripcion))) IN ('activo', 'activa')
    ORDER BY IdEstado;

    IF @IdEstadoActivo IS NULL
        SET @IdEstadoActivo = 1;

    IF @NumCupos <= 0 RETURN 0;
    IF @FechaCierre < @FechaMaxAplicacion RETURN 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO VacantesPractica 
        (Nombre, IdEstado, IdEmpresa, Requisitos, FechaMaxAplicacion, 
         NumeroCupos, FechaCierre, IdModalidad, Descripcion, Tipo)
        VALUES 
        (@Nombre, @IdEstadoActivo, @IdEmpresa, @Requisitos, @FechaMaxAplicacion,  -- ✅ CORREGIDO
         @NumCupos, @FechaCierre, @IdModalidad, @Descripcion, NULL);

        DECLARE @NewId INT = SCOPE_IDENTITY();

        IF @IdEspecialidad > 0
        BEGIN
            INSERT INTO EspecialidadesVacante (IdVacante, IdEspecialidad)
            VALUES (@NewId, @IdEspecialidad);
        END

        COMMIT TRANSACTION;
        RETURN @NewId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RETURN 0;
    END CATCH
END
GO

/* =========================================================
   POST: Editar Vacante
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.EditarVacanteSP
    @IdVacante INT,
    @Nombre NVARCHAR(255),
    @IdEmpresa INT,
    @IdEspecialidad INT,
    @NumCupos INT,
    @IdModalidad INT,
    @Requisitos NVARCHAR(MAX), 
    @Descripcion NVARCHAR(255),
    @FechaMaxAplicacion DATE,
    @FechaCierre DATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM VacantesPractica WHERE IdVacantePractica = @IdVacante)
        RETURN 0;

    IF @NumCupos <= 0 RETURN 0;
    IF @FechaCierre < @FechaMaxAplicacion RETURN 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE VacantesPractica
        SET Nombre = @Nombre,
            IdEmpresa = @IdEmpresa,
            Requisitos = @Requisitos,
            FechaMaxAplicacion = @FechaMaxAplicacion,
            NumeroCupos = @NumCupos,
            FechaCierre = @FechaCierre,
            IdModalidad = @IdModalidad,
            Descripcion = @Descripcion
        WHERE IdVacantePractica = @IdVacante;

        IF EXISTS (SELECT 1 FROM EspecialidadesVacante WHERE IdVacante = @IdVacante)
        BEGIN
            UPDATE EspecialidadesVacante
            SET IdEspecialidad = @IdEspecialidad
            WHERE IdVacante = @IdVacante;
        END
        ELSE
        BEGIN
            INSERT INTO EspecialidadesVacante (IdVacante, IdEspecialidad)
            VALUES (@IdVacante, @IdEspecialidad);
        END

        COMMIT TRANSACTION;
        RETURN @IdVacante;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RETURN 0;
    END CATCH
END
GO

/* =========================================================
   POST: Eliminar Vacante
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.EliminarVacanteSP
    @IdVacante INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM VacantesPractica WHERE IdVacantePractica = @IdVacante)
        RETURN 0;

    IF EXISTS (SELECT 1 FROM PracticaEstudiante WHERE IdVacante = @IdVacante)
        RETURN -1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM EspecialidadesVacante WHERE IdVacante = @IdVacante;
        DELETE FROM VacantesPractica WHERE IdVacantePractica = @IdVacante;

        COMMIT TRANSACTION;
        RETURN 1;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        RETURN 0;
    END CATCH
END
GO

USE SIGEP_WEB;
GO

DROP PROCEDURE IF EXISTS dbo.AsignarEstudianteSP;
GO

CREATE PROCEDURE dbo.AsignarEstudianteSP
    @IdVacante INT,
    @IdUsuario INT,
    @Resultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    PRINT '=== INICIO AsignarEstudianteSP ===';
    PRINT '@IdVacante: ' + CAST(@IdVacante AS VARCHAR);
    PRINT '@IdUsuario: ' + CAST(@IdUsuario AS VARCHAR);

    -- Variables para IDs de estados
    DECLARE @IdEstadoEnProceso   INT;
    DECLARE @IdEstadoAsignada    INT;
    DECLARE @IdEstadoRetirada    INT;
    DECLARE @IdEstadoAprobada    INT;
    DECLARE @IdEstadoEnCurso     INT;
    DECLARE @IdEstadoFinalizada  INT;
    DECLARE @IdEstadoRezagado    INT;

    -- Obtener IDs de estados
    SELECT @IdEstadoEnProceso  = IdEstado FROM Estados WHERE LOWER(LTRIM(RTRIM(Descripcion))) = 'en proceso de aplicacion';
    SELECT @IdEstadoAsignada   = IdEstado FROM Estados WHERE LOWER(LTRIM(RTRIM(Descripcion))) = 'asignada';
    SELECT @IdEstadoRetirada   = IdEstado FROM Estados WHERE LOWER(LTRIM(RTRIM(Descripcion))) = 'retirada';
    SELECT @IdEstadoAprobada   = IdEstado FROM Estados WHERE LOWER(LTRIM(RTRIM(Descripcion))) = 'aprobada';
    SELECT @IdEstadoEnCurso    = IdEstado FROM Estados WHERE LOWER(LTRIM(RTRIM(Descripcion))) = 'en curso';
    SELECT @IdEstadoFinalizada = IdEstado FROM Estados WHERE LOWER(LTRIM(RTRIM(Descripcion))) = 'finalizada';
    SELECT @IdEstadoRezagado   = IdEstado FROM Estados WHERE LOWER(LTRIM(RTRIM(Descripcion))) = 'rezagado';

    PRINT 'Estados cargados: EnProceso=' + CAST(@IdEstadoEnProceso AS VARCHAR) +
          ', Asignada=' + CAST(@IdEstadoAsignada AS VARCHAR);

    /* =========================================================
       VALIDACIÓN: Estudiante debe estar "aprobado" académicamente
       ========================================================= */
    DECLARE @EstadoAcademico BIT = NULL;

    SELECT @EstadoAcademico = EstadoAcademico
    FROM dbo.Usuarios
    WHERE IdUsuario = @IdUsuario;

    IF @EstadoAcademico IS NULL
    BEGIN
        PRINT 'ERROR: Usuario no existe';
        SET @Resultado = -6;   -- usuario no encontrado
        RETURN;
    END

    IF @EstadoAcademico = 0
    BEGIN
        PRINT 'ERROR: Estudiante rezagado (EstadoAcademico=0). No se permite asignar.';
        SET @Resultado = -5;   -- rezagado / no permitido
        RETURN;
    END

    -- Verificar que la vacante existe
    IF NOT EXISTS (SELECT 1 FROM VacantesPractica WHERE IdVacantePractica = @IdVacante)
    BEGIN
        PRINT 'ERROR: Vacante no existe';
        SET @Resultado = 0;
        RETURN;
    END

    -- Verificar cupos disponibles
    DECLARE @CuposOcupados INT;
    DECLARE @NumeroCupos INT;

    SELECT @NumeroCupos = NumeroCupos
    FROM VacantesPractica
    WHERE IdVacantePractica = @IdVacante;

    SELECT @CuposOcupados = COUNT(*)
    FROM PracticaEstudiante
    WHERE IdVacante = @IdVacante
      AND IdEstado IN (@IdEstadoAsignada, @IdEstadoAprobada, 8, 9, @IdEstadoEnCurso);

    PRINT 'Cupos totales: ' + CAST(@NumeroCupos AS VARCHAR);
    PRINT 'Cupos ocupados: ' + CAST(@CuposOcupados AS VARCHAR);

    IF @CuposOcupados >= @NumeroCupos
    BEGIN
        PRINT 'ERROR: No hay cupos disponibles';
        SET @Resultado = -2;
        RETURN;
    END

    -- Verificar si tiene práctica activa EN OTRA VACANTE
    IF EXISTS (
        SELECT 1
        FROM PracticaEstudiante
        WHERE IdUsuario = @IdUsuario
          AND IdVacante <> @IdVacante
          AND IdEstado IN (@IdEstadoAsignada, @IdEstadoAprobada, @IdEstadoEnCurso)
    )
    BEGIN
        PRINT 'ERROR: Estudiante ya tiene práctica activa en otra vacante';
        SET @Resultado = -1;
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @IdPracticaExistente INT = NULL;
        DECLARE @EstadoActual INT = NULL;

        SELECT TOP 1
            @IdPracticaExistente = IdPractica,
            @EstadoActual = IdEstado
        FROM PracticaEstudiante WITH (UPDLOCK, ROWLOCK)
        WHERE IdUsuario = @IdUsuario
          AND IdVacante = @IdVacante
        ORDER BY IdPractica DESC;

        PRINT 'Práctica existente: ' + ISNULL(CAST(@IdPracticaExistente AS VARCHAR), 'NULL');
        PRINT 'Estado actual: ' + ISNULL(CAST(@EstadoActual AS VARCHAR), 'NULL');

        IF @IdPracticaExistente IS NULL
        BEGIN
            PRINT 'INSERTANDO nuevo registro en estado "En Proceso"';

            INSERT INTO PracticaEstudiante (IdVacante, IdEstado, IdUsuario, FechaAplicacion)
            VALUES (@IdVacante, @IdEstadoEnProceso, @IdUsuario, GETDATE());

            SET @Resultado = 1;
            PRINT '=== ÉXITO: Registro creado ===';
        END
        ELSE
        BEGIN
            IF @EstadoActual = @IdEstadoEnProceso
            BEGIN
                PRINT 'ACTUALIZANDO de "En Proceso" a "Asignada"';

                UPDATE PracticaEstudiante
                SET IdEstado = @IdEstadoAsignada,
                    FechaAplicacion = GETDATE()
                WHERE IdPractica = @IdPracticaExistente;

                SET @Resultado = 1;
                PRINT '=== ÉXITO: Actualizado a Asignada ===';
            END
            ELSE IF @EstadoActual = @IdEstadoRetirada
            BEGIN
                PRINT 'ACTUALIZANDO de "Retirada" a "En Proceso"';

                UPDATE PracticaEstudiante
                SET IdEstado = @IdEstadoEnProceso,
                    FechaAplicacion = GETDATE()
                WHERE IdPractica = @IdPracticaExistente;

                SET @Resultado = 1;
                PRINT '=== ÉXITO: Reactivado a En Proceso ===';
            END
            ELSE IF @EstadoActual = @IdEstadoAsignada
            BEGIN
                PRINT 'AVISO: Ya está asignado';
                SET @Resultado = -3;
            END
            ELSE IF @EstadoActual IN (@IdEstadoAprobada, @IdEstadoEnCurso)
            BEGIN
                PRINT 'ERROR: No se puede modificar (Aprobada/En Curso)';
                SET @Resultado = -4;
            END
            ELSE IF @EstadoActual IN (@IdEstadoFinalizada, @IdEstadoRezagado)
            BEGIN
                PRINT 'INSERTANDO nueva práctica (la anterior queda como historial)';

                INSERT INTO PracticaEstudiante (IdVacante, IdEstado, IdUsuario, FechaAplicacion)
                VALUES (@IdVacante, @IdEstadoEnProceso, @IdUsuario, GETDATE());

                SET @Resultado = 1;
                PRINT '=== ÉXITO: Nueva práctica creada ===';
            END
            ELSE
            BEGIN
                PRINT 'ERROR: Estado no válido: ' + CAST(@EstadoActual AS VARCHAR);
                SET @Resultado = 0;
            END
        END

        COMMIT TRANSACTION;
        PRINT '=== COMMIT EXITOSO ===';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT 'ERROR EN CATCH: ' + ERROR_MESSAGE();
        PRINT 'ERROR NUMBER: ' + CAST(ERROR_NUMBER() AS VARCHAR);
        PRINT 'ERROR LINE: ' + CAST(ERROR_LINE() AS VARCHAR);
        SET @Resultado = 0;
    END CATCH
END
GO
/* =========================================================
   POST: Retirar Estudiante
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.RetirarEstudianteSP
    @IdVacante INT,
    @IdUsuario INT,
    @Comentario NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdPractica INT;

    SELECT @IdPractica = IdPractica
    FROM PracticaEstudiante
    WHERE IdVacante = @IdVacante
    AND IdUsuario = @IdUsuario;

    IF @IdPractica IS NULL
    BEGIN
        RETURN 0;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @IdEstadoInactivo INT;
        SELECT TOP 1 @IdEstadoInactivo = IdEstado 
        FROM Estados 
        WHERE LOWER(LTRIM(RTRIM(Descripcion))) IN ('inactivo', 'inactiva', 'retirado', 'retirada')
        ORDER BY IdEstado;

        IF @IdEstadoInactivo IS NULL
            SET @IdEstadoInactivo = 2;

        UPDATE PracticaEstudiante
        SET IdEstado = @IdEstadoInactivo
        WHERE IdPractica = @IdPractica;

        IF @Comentario IS NOT NULL AND LEN(@Comentario) > 0
        BEGIN
            INSERT INTO ComentariosPractica (Comentario, Fecha, IdUsuario, IdPractica, Tipo)
            VALUES (@Comentario, GETDATE(), @IdUsuario, @IdPractica, 'Retiro');
        END

        COMMIT TRANSACTION;

        RETURN 1;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        RETURN 0;
    END CATCH
END
GO

/* =========================================================
   POST: Desasignar Práctica
   ========================================================= */
USE SIGEP_WEB;
GO

/* =========================================================
   POST: Desasignar Práctica
   ========================================================= */
DROP PROCEDURE IF EXISTS dbo.DesasignarPracticaSP;
GO

CREATE PROCEDURE dbo.DesasignarPracticaSP
    @IdPractica INT,
    @Comentario NVARCHAR(MAX),
    @Resultado INT OUTPUT 
AS
BEGIN
    SET NOCOUNT ON;

    PRINT '========================================';
    PRINT '=== INICIO DesasignarPracticaSP ===';
    PRINT '========================================';
    PRINT '@IdPractica: ' + CAST(@IdPractica AS VARCHAR);
    PRINT '@Comentario: ' + ISNULL(@Comentario, '(NULL)');
    PRINT '';

    IF NOT EXISTS (SELECT 1 FROM PracticaEstudiante WHERE IdPractica = @IdPractica)
    BEGIN
        PRINT '❌ ERROR: La práctica con IdPractica=' + CAST(@IdPractica AS VARCHAR) + ' NO EXISTE';
        SET @Resultado = 0;
        RETURN;
    END

    PRINT '✅ Práctica encontrada';

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @IdEstadoRetirada INT = NULL;
        
        SELECT @IdEstadoRetirada = IdEstado 
        FROM Estados 
        WHERE LOWER(LTRIM(RTRIM(Descripcion))) = 'retirada';

        PRINT 'Estado "Retirada": ' + ISNULL(CAST(@IdEstadoRetirada AS VARCHAR), '(NULL)');

        IF @IdEstadoRetirada IS NULL
        BEGIN
            SELECT @IdEstadoRetirada = IdEstado 
            FROM Estados 
            WHERE LOWER(LTRIM(RTRIM(Descripcion))) IN ('inactivo', 'inactiva');

            PRINT 'Usando estado "Inactivo": ' + ISNULL(CAST(@IdEstadoRetirada AS VARCHAR), '(NULL)');
        END

        IF @IdEstadoRetirada IS NULL
        BEGIN
            PRINT '❌ ERROR CRÍTICO: No existe ningún estado válido (Retirada/Inactivo)';
            PRINT 'Estados disponibles en la tabla:';
            
            DECLARE @EstadosDisponibles NVARCHAR(MAX);
            SELECT @EstadosDisponibles = STRING_AGG(CAST(IdEstado AS VARCHAR) + '=' + Descripcion, ', ')
            FROM Estados;
            
            PRINT @EstadosDisponibles;

            ROLLBACK TRANSACTION;
            SET @Resultado = -2;  -- Código especial: estado no encontrado
            RETURN;
        END

        PRINT '✅ Estado a usar: IdEstado=' + CAST(@IdEstadoRetirada AS VARCHAR);

        DECLARE @IdUsuario INT;
        SELECT @IdUsuario = IdUsuario
        FROM PracticaEstudiante
        WHERE IdPractica = @IdPractica;

        PRINT 'IdUsuario: ' + CAST(@IdUsuario AS VARCHAR);

        UPDATE PracticaEstudiante
        SET IdEstado = @IdEstadoRetirada
        WHERE IdPractica = @IdPractica;

        PRINT '✅ Estado de práctica actualizado';

        DECLARE @ComentarioLimpio NVARCHAR(MAX) = LTRIM(RTRIM(@Comentario));

        IF @ComentarioLimpio IS NOT NULL AND LEN(@ComentarioLimpio) > 0
        BEGIN
            INSERT INTO ComentariosPractica (Comentario, Fecha, IdUsuario, IdPractica, Tipo)
            VALUES (@ComentarioLimpio, GETDATE(), @IdUsuario, @IdPractica, 'Desasignación');

            PRINT '✅ Comentario insertado: "' + LEFT(@ComentarioLimpio, 50) + '..."';
        END
        ELSE
        BEGIN
            PRINT '⚠️ AVISO: No se insertó comentario (vacío o NULL)';
        END

        COMMIT TRANSACTION;
        
        PRINT '';
        PRINT '========================================';
        PRINT '=== ✅ COMMIT EXITOSO ===';
        PRINT '========================================';

        SET @Resultado = 1;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT '';
        PRINT '========================================';
        PRINT '=== ❌ ERROR EN CATCH ===';
        PRINT '========================================';
        PRINT 'ERROR_MESSAGE: ' + ERROR_MESSAGE();
        PRINT 'ERROR_NUMBER: ' + CAST(ERROR_NUMBER() AS VARCHAR);
        PRINT 'ERROR_LINE: ' + CAST(ERROR_LINE() AS VARCHAR);
        PRINT 'ERROR_SEVERITY: ' + CAST(ERROR_SEVERITY() AS VARCHAR);
        PRINT 'ERROR_STATE: ' + CAST(ERROR_STATE() AS VARCHAR);
        
        SET @Resultado = 0;
    END CATCH
END
GO

PRINT '';
PRINT '✅ SP DesasignarPracticaSP creado exitosamente';
GO

/* =========================================================
   STORED PROCEDURES DE EMPRESAS
   ========================================================= */

CREATE OR ALTER PROCEDURE GuardarEmpresaSP
(
    @IdEmpresa INT = 0,
    @NombreEmpresa VARCHAR(255),
    @NombreContacto VARCHAR(255),
    @Email VARCHAR(255),
    @Telefono VARCHAR(50),
    @Provincia VARCHAR(255),
    @Canton VARCHAR(255),
    @Distrito VARCHAR(255),
    @DireccionExacta VARCHAR(MAX),
    @AreasAfinidad VARCHAR(255),
    @IdEmpresaOut INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdProvincia INT,
            @IdCanton INT,
            @IdDistrito INT,
            @IdDireccion INT;

    SELECT @IdProvincia = IdProvincia
    FROM Provincias
    WHERE Nombre = @Provincia;

    IF @IdProvincia IS NULL
    BEGIN
        INSERT INTO Provincias (Nombre) VALUES (@Provincia);
        SET @IdProvincia = SCOPE_IDENTITY();
    END;

    SELECT @IdCanton = IdCanton
    FROM Cantones
    WHERE Nombre = @Canton AND IdProvincia = @IdProvincia;

    IF @IdCanton IS NULL
    BEGIN
        INSERT INTO Cantones (Nombre, IdProvincia)
        VALUES (@Canton, @IdProvincia);
        SET @IdCanton = SCOPE_IDENTITY();
    END;

    SELECT @IdDistrito = IdDistrito
    FROM Distritos
    WHERE Nombre = @Distrito AND IdCanton = @IdCanton;

    IF @IdDistrito IS NULL
    BEGIN
        INSERT INTO Distritos (Nombre, IdCanton)
        VALUES (@Distrito, @IdCanton);
        SET @IdDistrito = SCOPE_IDENTITY();
    END;

    SELECT @IdDireccion = IdDireccion
    FROM Empresas
    WHERE IdEmpresa = @IdEmpresa;

    IF @IdEmpresa = 0
    BEGIN
        INSERT INTO Direcciones (IdDistrito, DireccionExacta)
        VALUES (@IdDistrito, @DireccionExacta);
        SET @IdDireccion = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        IF @IdDireccion IS NULL
        BEGIN
            INSERT INTO Direcciones (IdDistrito, DireccionExacta)
            VALUES (@IdDistrito, @DireccionExacta);
            SET @IdDireccion = SCOPE_IDENTITY();

            UPDATE Empresas
            SET IdDireccion = @IdDireccion
            WHERE IdEmpresa = @IdEmpresa;
        END
        ELSE
        BEGIN
            UPDATE Direcciones
            SET DireccionExacta = @DireccionExacta,
                IdDistrito = @IdDistrito
            WHERE IdDireccion = @IdDireccion;
        END
    END;

    IF @IdEmpresa = 0
    BEGIN
        INSERT INTO Empresas
        (NombreEmpresa, NombreContacto, IdDireccion, AreasAfinidad, IdEstado)
        VALUES (@NombreEmpresa, @NombreContacto, @IdDireccion, @AreasAfinidad, 1);
        SET @IdEmpresaOut = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE Empresas
        SET NombreEmpresa = @NombreEmpresa,
            NombreContacto = @NombreContacto,
            AreasAfinidad = @AreasAfinidad
        WHERE IdEmpresa = @IdEmpresa;
        SET @IdEmpresaOut = @IdEmpresa;
    END

    IF EXISTS(SELECT 1 FROM Emails WHERE IdEmpresa = @IdEmpresaOut)
        UPDATE Emails SET Email = @Email WHERE IdEmpresa = @IdEmpresaOut;
    ELSE
        INSERT INTO Emails (IdEmpresa, Email) VALUES (@IdEmpresaOut, @Email);

    IF EXISTS(SELECT 1 FROM Telefonos WHERE IdEmpresa = @IdEmpresaOut)
        UPDATE Telefonos SET Telefono = @Telefono WHERE IdEmpresa = @IdEmpresaOut;
    ELSE
        INSERT INTO Telefonos (IdEmpresa, Telefono) VALUES (@IdEmpresaOut, @Telefono);
END;
GO

CREATE OR ALTER PROCEDURE ConsultarEmpresaSP
(
    @IdEmpresa INT
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        e.IdEmpresa,
        e.NombreEmpresa,
        e.NombreContacto,
        em.Email,
        t.Telefono,
        p.Nombre AS Provincia,
        c.Nombre AS Canton,
        d.Nombre AS Distrito,
        dir.DireccionExacta,
        e.AreasAfinidad
    FROM Empresas e
    LEFT JOIN Direcciones dir       ON e.IdDireccion = dir.IdDireccion
    LEFT JOIN Distritos d           ON dir.IdDistrito = d.IdDistrito
    LEFT JOIN Cantones c            ON d.IdCanton = c.IdCanton
    LEFT JOIN Provincias p          ON c.IdProvincia = p.IdProvincia
    LEFT JOIN Emails em             ON em.IdEmpresa = e.IdEmpresa
    LEFT JOIN Telefonos t           ON t.IdEmpresa = e.IdEmpresa
    WHERE e.IdEmpresa = @IdEmpresa;
END
GO

CREATE OR ALTER PROCEDURE ListarEmpresasSP
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        e.IdEmpresa,
        e.NombreEmpresa,
        e.AreasAfinidad AS AreasAfinidad,
        ISNULL(p.Nombre,'') +
        CASE WHEN c.Nombre IS NOT NULL THEN ', ' + c.Nombre ELSE '' END +
        CASE WHEN d.Nombre IS NOT NULL THEN ', ' + d.Nombre ELSE '' END AS Ubicacion,
        (SELECT COUNT(*) 
         FROM VacantesPractica v 
         WHERE v.IdEmpresa = e.IdEmpresa) AS HistorialVacantes
    FROM Empresas e
    LEFT JOIN Direcciones dir   ON e.IdDireccion = dir.IdDireccion
    LEFT JOIN Distritos d       ON dir.IdDistrito = d.IdDistrito
    LEFT JOIN Cantones c        ON d.IdCanton = c.IdCanton
    LEFT JOIN Provincias p      ON c.IdProvincia = p.IdProvincia
    WHERE e.IdEstado = 1;
END
GO

CREATE OR ALTER PROCEDURE ActualizarEmpresaSP
(
    @IdEmpresa INT,
    @NombreEmpresa VARCHAR(255),
    @NombreContacto VARCHAR(255),
    @Email VARCHAR(255),
    @Telefono VARCHAR(50),
    @Provincia VARCHAR(255),
    @Canton VARCHAR(255),
    @Distrito VARCHAR(255),
    @DireccionExacta VARCHAR(MAX),
    @AreasAfinidad VARCHAR(255)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdProvincia INT,
            @IdCanton INT,
            @IdDistrito INT,
            @IdDireccion INT;

    SELECT @IdProvincia = IdProvincia
    FROM Provincias
    WHERE Nombre = @Provincia;

    IF @IdProvincia IS NULL
    BEGIN
        INSERT INTO Provincias (Nombre) VALUES (@Provincia);
        SET @IdProvincia = SCOPE_IDENTITY();
    END;

    SELECT @IdCanton = IdCanton
    FROM Cantones
    WHERE Nombre = @Canton AND IdProvincia = @IdProvincia;

    IF @IdCanton IS NULL
    BEGIN
        INSERT INTO Cantones (Nombre, IdProvincia)
        VALUES (@Canton, @IdProvincia);
        SET @IdCanton = SCOPE_IDENTITY();
    END;

    SELECT @IdDistrito = IdDistrito
    FROM Distritos
    WHERE Nombre = @Distrito AND IdCanton = @IdCanton;

    IF @IdDistrito IS NULL
    BEGIN
        INSERT INTO Distritos (Nombre, IdCanton)
        VALUES (@Distrito, @IdCanton);
        SET @IdDistrito = SCOPE_IDENTITY();
    END;

    SELECT @IdDireccion = IdDireccion 
    FROM Empresas 
    WHERE IdEmpresa = @IdEmpresa;

    IF @IdDireccion IS NULL
    BEGIN
        INSERT INTO Direcciones (IdDistrito, DireccionExacta)
        VALUES (@IdDistrito, @DireccionExacta);
        SET @IdDireccion = SCOPE_IDENTITY();

        UPDATE Empresas
        SET IdDireccion = @IdDireccion
        WHERE IdEmpresa = @IdEmpresa;
    END
    ELSE
    BEGIN
        UPDATE Direcciones
        SET DireccionExacta = @DireccionExacta,
            IdDistrito = @IdDistrito
        WHERE IdDireccion = @IdDireccion;
    END

    UPDATE Empresas
    SET NombreEmpresa = @NombreEmpresa,
        NombreContacto = @NombreContacto,
        AreasAfinidad = @AreasAfinidad
    WHERE IdEmpresa = @IdEmpresa;

    IF EXISTS(SELECT 1 FROM Emails WHERE IdEmpresa = @IdEmpresa)
        UPDATE Emails SET Email = @Email WHERE IdEmpresa = @IdEmpresa;
    ELSE
        INSERT INTO Emails (IdEmpresa, Email)
        VALUES (@IdEmpresa, @Email);

    IF EXISTS(SELECT 1 FROM Telefonos WHERE IdEmpresa = @IdEmpresa)
        UPDATE Telefonos SET Telefono = @Telefono WHERE IdEmpresa = @IdEmpresa;
    ELSE
        INSERT INTO Telefonos (IdEmpresa, Telefono)
        VALUES (@IdEmpresa, @Telefono);
END
GO

CREATE OR ALTER PROCEDURE EliminarEmpresaSP
(
    @IdEmpresa INT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Inactivo INT = 2;
    DECLARE @Cancelado INT = 3;

    UPDATE Empresas
    SET IdEstado = @Inactivo
    WHERE IdEmpresa = @IdEmpresa;

    UPDATE VacantesPractica
    SET IdEstado = @Cancelado
    WHERE IdEmpresa = @IdEmpresa;
END
GO

/* =========================================================
   STORED PROCEDURES ADMINISTRATIVOS
   ========================================================= */

CREATE OR ALTER PROCEDURE ObtenerEspecialidadesSP
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        IdEspecialidad,
        Nombre
    FROM Especialidades
    WHERE IdEstado = (SELECT IdEstado FROM Estados WHERE Descripcion = 'Activo')
    ORDER BY Nombre;
END
GO

CREATE OR ALTER PROCEDURE ActualizarEstadoAcademicoSP
    @IdUsuario INT,
    @NuevoEstado BIT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        UPDATE Usuarios
        SET EstadoAcademico = @NuevoEstado
        WHERE IdUsuario = @IdUsuario AND IdRol = 1;

        IF @@ROWCOUNT > 0
            SELECT 1 AS Resultado, 'Estado académico actualizado correctamente' AS Mensaje;
        ELSE
            SELECT 0 AS Resultado, 'Estudiante no encontrado' AS Mensaje;
    END TRY
    BEGIN CATCH
        SELECT 0 AS Resultado, ERROR_MESSAGE() AS Mensaje;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE EliminarDocumentoSP
    @IdDocumento INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        DELETE FROM Documentos WHERE IdDocumento = @IdDocumento;
        SELECT 1 AS Resultado, 'Documento eliminado correctamente' AS Mensaje;
    END TRY
    BEGIN CATCH
        SELECT 0 AS Resultado, ERROR_MESSAGE() AS Mensaje;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE ListarEstudiantesSP
    @IdCoordinador INT = NULL,
    @Estado VARCHAR(50) = NULL,
    @IdEspecialidad INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @EstadoClean VARCHAR(50) = NULLIF(LTRIM(RTRIM(@Estado)), '');
    DECLARE @IdEspecialidadClean INT = NULLIF(@IdEspecialidad, 0);

    SELECT 
        u.IdUsuario,
        ISNULL(u.Cedula, '') AS Cedula,
        u.Nombre + ' ' + u.Apellido1 + ' ' + ISNULL(u.Apellido2, '') AS NombreCompleto,
        ISNULL((SELECT TOP 1 Telefono FROM Telefonos WHERE IdUsuario = u.IdUsuario ORDER BY IdTelefono DESC), '') AS Telefono,
        ISNULL((SELECT TOP 1 e.Nombre 
         FROM UsuarioEspecialidad ue 
         INNER JOIN Especialidades e ON ue.IdEspecialidad = e.IdEspecialidad
         WHERE ue.IdUsuario = u.IdUsuario 
         ORDER BY ue.IdUsuarioEspecialidad DESC), 'Sin Especialidad') AS EspecialidadNombre,
        CAST(ISNULL(u.EstadoAcademico, 0) AS BIT) AS EstadoAcademico,
        ISNULL((SELECT TOP 1 est.Descripcion 
         FROM PracticaEstudiante pe 
         INNER JOIN Estados est ON pe.IdEstado = est.IdEstado
         WHERE pe.IdUsuario = u.IdUsuario 
         ORDER BY pe.IdPractica DESC), 'Sin Procesos Activos') AS EstadoPractica,
        CASE 
            WHEN ISNULL(u.EstadoAcademico, 0) = 1 THEN 1
            ELSE 0
        END AS IdEstado
    FROM Usuarios u
    WHERE u.IdRol = 1
        AND ISNULL(u.IdEstado, 0) != 0
        AND (@EstadoClean IS NULL 
             OR (@EstadoClean = 'Aprobada' AND u.EstadoAcademico = 1)
             OR (@EstadoClean = 'Rezagado' AND u.EstadoAcademico = 0))
        AND (@IdEspecialidadClean IS NULL OR @IdEspecialidadClean = 0 OR 
             EXISTS (SELECT 1 FROM UsuarioEspecialidad ue 
                     WHERE ue.IdUsuario = u.IdUsuario AND ue.IdEspecialidad = @IdEspecialidadClean))
    ORDER BY u.Nombre, u.Apellido1;
END
GO

CREATE OR ALTER PROCEDURE ConsultarEstudianteSP
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        u.Cedula,
        u.Nombre,
        u.Apellido1,
        u.Apellido2,
        ISNULL((SELECT TOP 1 Email FROM Emails WHERE IdUsuario = u.IdUsuario ORDER BY IdEmail DESC), '') AS Correo,
        ISNULL((SELECT TOP 1 Telefono FROM Telefonos WHERE IdUsuario = u.IdUsuario ORDER BY IdTelefono DESC), '') AS Telefono,
        u.FechaNacimiento,
        ISNULL(p.Nombre, '') AS Provincia,
        ISNULL(c.Nombre, '') AS Canton,
        ISNULL(dist.Nombre, '') AS Distrito,
        ISNULL(dir.DireccionExacta, '') AS DireccionExacta,
        ISNULL((SELECT TOP 1 e.Nombre 
         FROM UsuarioEspecialidad ue 
         INNER JOIN Especialidades e ON ue.IdEspecialidad = e.IdEspecialidad
         WHERE ue.IdUsuario = u.IdUsuario 
         ORDER BY ue.IdUsuarioEspecialidad DESC), '') AS Especialidad,
        ISNULL(s.Seccion, '') AS Seccion
    FROM Usuarios u
    LEFT JOIN Direcciones dir ON u.IdDireccion = dir.IdDireccion
    LEFT JOIN Distritos dist ON dir.IdDistrito = dist.IdDistrito
    LEFT JOIN Cantones c ON dist.IdCanton = c.IdCanton
    LEFT JOIN Provincias p ON c.IdProvincia = p.IdProvincia
    LEFT JOIN Secciones s ON u.IdSeccion = s.IdSeccion
    WHERE u.IdUsuario = @IdUsuario;

    SELECT 
        enc.Nombre + ' ' + enc.Apellido1 + ' ' + ISNULL(enc.Apellido2, '') AS Nombre,
        ISNULL((SELECT TOP 1 Telefono FROM Telefonos WHERE IdEncargado = enc.IdEncargado ORDER BY IdTelefono DESC), '') AS Telefono,
        ISNULL(enc.Ocupacion, '') AS Ocupacion
    FROM EstudianteEncargado ee
    INNER JOIN Encargados enc ON ee.IdEncargado = enc.IdEncargado
    WHERE ee.IdUsuario = @IdUsuario;

    SELECT 
        IdDocumento,
        Documento
    FROM Documentos
    WHERE IdUsuario = @IdUsuario
    ORDER BY FechaSubida DESC;

    SELECT 
        pe.IdPractica AS IdPostulacion,
        pe.IdVacante,
        pe.IdUsuario,
        emp.NombreEmpresa AS Empresa,
        ISNULL(est.Descripcion, '') AS Estado
    FROM PracticaEstudiante pe
    INNER JOIN VacantesPractica vp ON pe.IdVacante = vp.IdVacantePractica
    LEFT JOIN Estados est ON pe.IdEstado = est.IdEstado
    INNER JOIN Empresas emp ON vp.IdEmpresa = emp.IdEmpresa
    WHERE pe.IdUsuario = @IdUsuario
    ORDER BY pe.IdPractica DESC;
END
GO

CREATE OR ALTER PROCEDURE ConsultarUsuariosSP
    @Rol VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        u.IdUsuario,
        (u.Nombre + ' ' + u.Apellido1 + ' ' + ISNULL(u.Apellido2, '')) AS Nombre,
        u.Cedula,
        (SELECT TOP 1 Email FROM Emails WHERE IdUsuario = u.IdUsuario) AS Email,
        r.Descripcion AS Rol,
        CASE 
            WHEN u.IdEstado = 1 THEN 'Activo'
            ELSE 'Inactivo'
        END AS Estado,
        u.IdEstado
    FROM Usuarios u
    INNER JOIN Roles r ON u.IdRol = r.IdRol
    INNER JOIN Estados e ON u.IdEstado = e.IdEstado
    WHERE (@Rol IS NULL OR r.Descripcion = @Rol)
    ORDER BY u.IdEstado ASC, u.Nombre ASC
END
GO

CREATE OR ALTER PROCEDURE CambiarEstadoUsuarioSP
    @IdUsuario INT,
    @NuevoEstado VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @IdEstado INT
    
    IF @NuevoEstado = 'Activo'
        SET @IdEstado = 1
    ELSE IF @NuevoEstado = 'Inactivo'
        SET @IdEstado = 2
    ELSE
    BEGIN
        RETURN 0
    END
    
    IF NOT EXISTS (SELECT 1 FROM Usuarios WHERE IdUsuario = @IdUsuario)
    BEGIN
        RETURN 0
    END
    
    UPDATE Usuarios
    SET IdEstado = @IdEstado
    WHERE IdUsuario = @IdUsuario
    
    RETURN @@ROWCOUNT
END
GO

CREATE OR ALTER PROCEDURE CambiarRolUsuarioSP
    @IdUsuario INT,
    @Rol VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @IdRol INT
    
    SELECT @IdRol = IdRol
    FROM Roles
    WHERE Descripcion = @Rol
    
    IF @IdRol IS NULL
    BEGIN
        RETURN 0
    END
    
    IF NOT EXISTS (SELECT 1 FROM Usuarios WHERE IdUsuario = @IdUsuario)
    BEGIN
        RETURN 0
    END
    
    UPDATE Usuarios
    SET IdRol = @IdRol
    WHERE IdUsuario = @IdUsuario
    
    RETURN @@ROWCOUNT
END
GO

CREATE OR ALTER PROCEDURE ConsultarEspecialidadesSP
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        IdEspecialidad,
        Nombre,
        IdEstado
    FROM Especialidades
    ORDER BY IdEstado ASC, Nombre ASC
END
GO

CREATE OR ALTER PROCEDURE CrearEspecialidadSP
    @Nombre VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM Especialidades WHERE Nombre = @Nombre)
    BEGIN
        DECLARE @EstadoExistente INT
        SELECT @EstadoExistente = IdEstado
        FROM Especialidades
        WHERE Nombre = @Nombre
        
        IF @EstadoExistente = 2
            RETURN -1 
        ELSE
            RETURN 0   
    END
    
    INSERT INTO Especialidades (Nombre, IdEstado)
    VALUES (@Nombre, 1)
    
    RETURN @@ROWCOUNT
END
GO

CREATE OR ALTER PROCEDURE EditarEspecialidadSP
    @Id INT,
    @Nombre VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM Especialidades WHERE IdEspecialidad = @Id)
    BEGIN
        RETURN 0
    END
    
    IF EXISTS (SELECT 1 FROM Especialidades WHERE Nombre = @Nombre AND IdEspecialidad <> @Id)
    BEGIN
        DECLARE @EstadoDuplicado INT
        SELECT @EstadoDuplicado = IdEstado
        FROM Especialidades
        WHERE Nombre = @Nombre AND IdEspecialidad <> @Id
        
        IF @EstadoDuplicado = 2
            RETURN -1  
        ELSE
            RETURN 0   
    END
    
    UPDATE Especialidades
    SET Nombre = @Nombre
    WHERE IdEspecialidad = @Id
    
    RETURN @@ROWCOUNT
END
GO

CREATE OR ALTER PROCEDURE CambiarEstadoEspecialidadSP
    @Id INT,
    @NuevoEstado VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @IdEstado INT
    
    IF @NuevoEstado = 'Activo'
        SET @IdEstado = 1
    ELSE IF @NuevoEstado = 'Inactivo'
        SET @IdEstado = 2
    ELSE
    BEGIN
        RETURN 0
    END
    
    IF @IdEstado = 2
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM UsuarioEspecialidad ue
            INNER JOIN Usuarios u ON ue.IdUsuario = u.IdUsuario
            WHERE ue.IdEspecialidad = @Id AND u.IdEstado = 1
        )
        BEGIN
            RETURN -1  
        END
    END
    
    IF NOT EXISTS (SELECT 1 FROM Especialidades WHERE IdEspecialidad = @Id)
    BEGIN
        RETURN 0
    END
    
    UPDATE Especialidades
    SET IdEstado = @IdEstado
    WHERE IdEspecialidad = @Id
    
    RETURN @@ROWCOUNT
END
GO

CREATE OR ALTER PROCEDURE ConsultarSeccionesSP
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        IdSeccion,
        Seccion,
        IdEstado
    FROM Secciones
    ORDER BY IdEstado ASC, Seccion ASC
END
GO

CREATE OR ALTER PROCEDURE CrearSeccionSP
    @NombreSeccion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM Secciones WHERE Seccion = @NombreSeccion)
    BEGIN
        DECLARE @EstadoExistente INT
        SELECT @EstadoExistente = IdEstado
        FROM Secciones
        WHERE Seccion = @NombreSeccion
        
        IF @EstadoExistente = 2
            RETURN -1  
        ELSE
            RETURN 0   
    END
    
    INSERT INTO Secciones (Seccion, IdEstado)
    VALUES (@NombreSeccion, 1)
    
    RETURN @@ROWCOUNT
END
GO

CREATE OR ALTER PROCEDURE EditarSeccionSP
    @Id INT,
    @NombreSeccion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM Secciones WHERE IdSeccion = @Id)
    BEGIN
        RETURN 0
    END
    
    IF EXISTS (SELECT 1 FROM Secciones WHERE Seccion = @NombreSeccion AND IdSeccion <> @Id)
    BEGIN
        DECLARE @EstadoDuplicado INT
        SELECT @EstadoDuplicado = IdEstado
        FROM Secciones
        WHERE Seccion = @NombreSeccion AND IdSeccion <> @Id
        
        IF @EstadoDuplicado = 2
            RETURN -1 
        ELSE
            RETURN 0  
    END
    
    UPDATE Secciones
    SET Seccion = @NombreSeccion
    WHERE IdSeccion = @Id
    
    RETURN @@ROWCOUNT
END
GO

CREATE OR ALTER PROCEDURE CambiarEstadoSeccionSP
    @Id INT,
    @NuevoEstado VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @IdEstado INT
    
    IF @NuevoEstado = 'Activo'
        SET @IdEstado = 1
    ELSE IF @NuevoEstado = 'Inactivo'
        SET @IdEstado = 2
    ELSE
    BEGIN
        RETURN 0
    END
    
    IF @IdEstado = 2
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM Usuarios
            WHERE IdSeccion = @Id AND IdEstado = 1
        )
        BEGIN
            RETURN -1
        END
    END
    
    IF NOT EXISTS (SELECT 1 FROM Secciones WHERE IdSeccion = @Id)
    BEGIN
        RETURN 0
    END
    
    UPDATE Secciones
    SET IdEstado = @IdEstado
    WHERE IdSeccion = @Id
    
    RETURN @@ROWCOUNT
END
GO

PRINT '========================================';
PRINT '✅ TODOS LOS SPs ACTUALIZADOS CORRECTAMENTE';
PRINT '========================================';
PRINT '';
PRINT 'CAMBIOS PRINCIPALES:';
PRINT '1. ✅ @Requerimientos → @Requisitos en CrearVacanteSP';
PRINT '2. ✅ @Requerimientos → @Requisitos en EditarVacanteSP';
PRINT '3. ✅ Alias Requerimientos → Requisitos en GetVacantesSP';
PRINT '4. ✅ Alias Requerimientos → Requisitos en DetalleVacanteSP';
PRINT '';
PRINT 'ALINEACIÓN COMPLETA:';
PRINT '- Base de Datos: VacantesPractica.Requisitos';
PRINT '- SPs (Parámetros): @Requisitos';
PRINT '- SPs (SELECTs): Devuelven columna "Requisitos"';
PRINT '- API DTOs: Propiedad "Requisitos"';
PRINT '- Web ViewModels: Propiedad "Requisitos"';
PRINT '';
PRINT '========================================';

USE SIGEP_WEB;
GO

/* =========================================================
   SP AUXILIARES - Para listas desplegables y catálogos
   ========================================================= */

-- ============================================================
-- Obtener Estados
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.ObtenerEstadosSP
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        CAST(IdEstado AS VARCHAR(10)) AS value,
        Descripcion AS text
    FROM Estados
    WHERE IdEstado > 0
    ORDER BY Descripcion;
END
GO

-- ============================================================
-- Obtener Especialidades
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.ObtenerEspecialidadesListaSP
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        CAST(IdEspecialidad AS VARCHAR(10)) AS value,
        Nombre AS text
    FROM Especialidades
    WHERE IdEstado = 1
    ORDER BY Nombre;
END
GO

-- ============================================================
-- Obtener Empresas Activas
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.ObtenerEmpresasListaSP
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        CAST(IdEmpresa AS VARCHAR(10)) AS value,
        NombreEmpresa AS text
    FROM Empresas
    WHERE IdEstado = 1
    ORDER BY NombreEmpresa;
END
GO

-- ============================================================
-- Obtener Modalidades
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.ObtenerModalidadesSP
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        CAST(IdModalidad AS VARCHAR(10)) AS value,
        Descripcion AS text
    FROM Modalidades
    ORDER BY Descripcion;
END
GO
