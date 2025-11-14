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
   Controller: GET api/vacantes/listar?idEstado=&idEspecialidad=&idModalidad=
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.GetVacantesSP
    @IdEstado       INT = 0,
    @IdEspecialidad INT = 0,
    @IdModalidad    INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdE_Asig   INT = dbo.fn_IdEstado('Asignada');
    DECLARE @IdE_Curso  INT = dbo.fn_IdEstado('En Curso');
    DECLARE @IdE_Aprob  INT = dbo.fn_IdEstado('Aprobada');
    DECLARE @IdE_Fin    INT = dbo.fn_IdEstado('Finalizada');
    DECLARE @IdE_Rezag  INT = dbo.fn_IdEstado('Rezagado');

    ;WITH Esp AS (
        SELECT ev.IdVacante,
               STRING_AGG(e.Nombre, ', ') WITHIN GROUP (ORDER BY e.Nombre) AS EspecialidadNombre
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
        v.Nombre,
        emp.IdEmpresa,
        emp.NombreEmpresa              AS EmpresaNombre,
        COALESCE(esp.EspecialidadNombre, '—') AS EspecialidadNombre,
        v.Requisitos                   AS Requerimientos,
        v.NumeroCupos                  AS NumCupos,
        COALESCE(po.NumPostulados, 0)  AS NumPostulados,
        est.Descripcion                AS EstadoNombre,
        v.IdModalidad,
        v.Descripcion,
        v.FechaMaxAplicacion,
        v.FechaCierre,
        v.Tipo
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
    ORDER BY v.Nombre;
END
GO

/* =========================================================
   GET: Detalle Vacante
   Controller: GET api/vacantes/detalle/{id}
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.DetalleVacanteSP
    @IdVacante INT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Esp AS (
        SELECT ev.IdVacante,
               STRING_AGG(e.Nombre, ', ') WITHIN GROUP (ORDER BY e.Nombre) AS Especialidades
        FROM EspecialidadesVacante ev
        INNER JOIN Especialidades e ON e.IdEspecialidad = ev.IdEspecialidad
        WHERE ev.IdVacante = @IdVacante
        GROUP BY ev.IdVacante
    ),
    Ubi AS (
        SELECT
            emp.IdEmpresa,
            CONCAT(
                ISNULL(p.Nombre, ''), CASE WHEN p.Nombre IS NULL THEN '' ELSE ', ' END,
                ISNULL(c.Nombre, ''), CASE WHEN c.Nombre IS NULL THEN '' ELSE ', ' END,
                ISNULL(d.Nombre, ''), CASE WHEN d.Nombre IS NULL THEN '' ELSE ', ' END,
                ISNULL(dir.DireccionExacta, '')
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
        v.IdModalidad,
        v.Descripcion,
        v.Requisitos       AS Requerimientos,
        v.NumeroCupos      AS NumCupos,
        v.FechaMaxAplicacion,
        v.FechaCierre,
        v.Tipo,
        e.Descripcion      AS EstadoNombre,
        COALESCE(esp.Especialidades,'—') AS Especialidades,
        COALESCE(u.Ubicacion,'No registrada') AS Ubicacion
    FROM VacantesPractica v
    INNER JOIN Empresas emp ON emp.IdEmpresa = v.IdEmpresa
    INNER JOIN Estados e    ON e.IdEstado  = v.IdEstado
    LEFT  JOIN Esp esp      ON esp.IdVacante = v.IdVacantePractica
    LEFT  JOIN Ubi u        ON u.IdEmpresa = v.IdEmpresa
    WHERE v.IdVacantePractica = @IdVacante;
END
GO

/* =========================================================
   GET: Ubicación Empresa
   Controller: GET api/vacantes/ubicacion-empresa?idEmpresa=
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.ObtenerUbicacionEmpresaSP
    @IdEmpresa INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        Ubicacion = CONCAT(
            ISNULL(p.Nombre, ''), CASE WHEN p.Nombre IS NULL THEN '' ELSE ', ' END,
            ISNULL(c.Nombre, ''), CASE WHEN c.Nombre IS NULL THEN '' ELSE ', ' END,
            ISNULL(d.Nombre, ''), CASE WHEN d.Nombre IS NULL THEN '' ELSE ', ' END,
            ISNULL(dir.DireccionExacta, '')
        )
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
   Controller: POST api/vacantes/crear
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.CrearVacanteSP
    @Nombre NVARCHAR(255),
    @IdEmpresa INT,
    @IdEspecialidad INT,
    @NumCupos INT,
    @IdModalidad INT,
    @Requerimientos NVARCHAR(MAX),
    @Descripcion NVARCHAR(255),
    @FechaMaxAplicacion DATE,
    @FechaCierre DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdEstadoActivo INT = dbo.fn_IdEstado('Activo');
    IF @IdEstadoActivo IS NULL
    BEGIN
        RAISERROR('No existe estado "Activo" en Estados.',16,1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRAN;

        INSERT INTO VacantesPractica
        (Nombre, IdEstado, IdEmpresa, Requisitos, FechaMaxAplicacion, NumeroCupos, FechaCierre, IdModalidad, Descripcion, Tipo)
        VALUES
        (@Nombre, @IdEstadoActivo, @IdEmpresa, @Requerimientos, @FechaMaxAplicacion, @NumCupos, @FechaCierre, @IdModalidad, @Descripcion, NULL);

        DECLARE @NewId INT = SCOPE_IDENTITY();

        IF @IdEspecialidad IS NOT NULL AND @IdEspecialidad > 0
        BEGIN
            INSERT INTO EspecialidadesVacante (IdVacante, IdEspecialidad)
            VALUES (@NewId, @IdEspecialidad);
        END

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        ROLLBACK TRAN;
        THROW;
    END CATCH
END
GO

/* =========================================================
   POST: Editar Vacante
   Controller: POST api/vacantes/editar
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.EditarVacanteSP
    @IdVacante INT,
    @Nombre NVARCHAR(255),
    @IdEmpresa INT,
    @IdEspecialidad INT,
    @NumCupos INT,
    @IdModalidad INT,
    @Requerimientos NVARCHAR(MAX),
    @Descripcion NVARCHAR(255),
    @FechaMaxAplicacion DATE,
    @FechaCierre DATE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        UPDATE VacantesPractica
        SET Nombre = @Nombre,
            IdEmpresa = @IdEmpresa,
            Requisitos = @Requerimientos,
            NumeroCupos = @NumCupos,
            IdModalidad = @IdModalidad,
            Descripcion = @Descripcion,
            FechaMaxAplicacion = @FechaMaxAplicacion,
            FechaCierre = @FechaCierre
        WHERE IdVacantePractica = @IdVacante;

        IF @IdEspecialidad IS NOT NULL AND @IdEspecialidad > 0
        BEGIN
            -- Mantener una especialidad principal (si usas varias, quita estas dos líneas y gestiona aparte)
            DELETE FROM EspecialidadesVacante WHERE IdVacante = @IdVacante;
            INSERT INTO EspecialidadesVacante (IdVacante, IdEspecialidad) VALUES (@IdVacante, @IdEspecialidad);
        END

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        ROLLBACK TRAN;
        THROW;
    END CATCH
END
GO

/* =========================================================
   POST: Eliminar/Archivar Vacante
   Controller: POST api/vacantes/eliminar
   Devuelve (ok, message)
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.EliminarVacanteSP
    @IdVacante INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdE_Asig  INT = dbo.fn_IdEstado('Asignada');
    DECLARE @IdE_Curso INT = dbo.fn_IdEstado('En Curso');
    DECLARE @IdE_Aprob INT = dbo.fn_IdEstado('Aprobada');
    DECLARE @IdE_Fin   INT = dbo.fn_IdEstado('Finalizada');
    DECLARE @IdE_Rezag INT = dbo.fn_IdEstado('Rezagado');
    DECLARE @IdE_Arch  INT = dbo.fn_IdEstado('Archivado');

    IF @IdE_Arch IS NULL
    BEGIN
        SELECT 0 AS ok, 'No existe estado "Archivado".' AS message;
        RETURN;
    END

    IF EXISTS (
        SELECT 1 FROM PracticaEstudiante p
        WHERE p.IdVacante = @IdVacante
          AND p.IdEstado IN (@IdE_Asig,@IdE_Curso,@IdE_Aprob,@IdE_Fin,@IdE_Rezag)
    )
    BEGIN
        SELECT 0 AS ok, 'No se puede archivar: hay estudiantes con proceso activo.' AS message;
        RETURN;
    END

    UPDATE VacantesPractica
    SET IdEstado = @IdE_Arch
    WHERE IdVacantePractica = @IdVacante;

    SELECT 1 AS ok, 'Vacante archivada correctamente.' AS message;
END
GO

/* =========================================================
   GET: Postulaciones por Vacante
   Controller: GET api/vacantes/postulaciones?idVacante=
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
   Controller: GET api/vacantes/visualizacion-postulacion?idVacante=&idUsuario=
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
   GET: Estudiantes para Asignar (sin rol profesor)
   Controller: GET api/vacantes/estudiantes-asignar?idVacante=&idUsuarioSesion=
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

    -- especialidades que requiere la vacante
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
        -- Estado general (último)
        EstadoPractica = ISNULL((
            SELECT TOP 1 e1.Descripcion
            FROM PracticaEstudiante p1
            INNER JOIN Estados e1 ON e1.IdEstado = p1.IdEstado
            WHERE p1.IdUsuario = u.IdUsuario
            ORDER BY p1.IdPractica DESC
        ), 'Sin proceso activo'),
        -- Estado con esta vacante (último)
        EstadoVacante = ISNULL((
            SELECT TOP 1 e2.Descripcion
            FROM PracticaEstudiante p2
            INNER JOIN Estados e2 ON e2.IdEstado = p2.IdEstado
            WHERE p2.IdUsuario = u.IdUsuario AND p2.IdVacante = @IdVacante
            ORDER BY p2.IdPractica DESC
        ), 'Sin proceso activo'),
        -- IdPractica último con esta vacante
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
   POST: Asignar Estudiante (2 clics: En Proceso -> Asignada)
   Controller: POST api/vacantes/asignar-estudiante
   Devuelve (ok, message)
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.AsignarEstudianteSP
    @IdVacante INT,
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NumCupos INT, @Ocupados INT;
    DECLARE @IdE_Proc  INT = dbo.fn_IdEstado('En Proceso de Aplicacion');
    DECLARE @IdE_Asig  INT = dbo.fn_IdEstado('Asignada');
    DECLARE @IdE_Curso INT = dbo.fn_IdEstado('En Curso');
    DECLARE @IdE_Aprob INT = dbo.fn_IdEstado('Aprobada');
    DECLARE @IdE_Fin   INT = dbo.fn_IdEstado('Finalizada');
    DECLARE @IdE_Rezag INT = dbo.fn_IdEstado('Rezagado');
    DECLARE @IdE_Ret   INT = dbo.fn_IdEstado('Retirada');

    IF @IdE_Proc IS NULL OR @IdE_Asig IS NULL OR @IdE_Ret IS NULL
    BEGIN
        SELECT 0 AS ok, 'Estados requeridos no existen (En Proceso, Asignada, Retirada).' AS message;
        RETURN;
    END

    SELECT @NumCupos = NumeroCupos FROM VacantesPractica WHERE IdVacantePractica = @IdVacante;
    IF @NumCupos IS NULL
    BEGIN
        SELECT 0 AS ok, 'Vacante no encontrada.' AS message; RETURN;
    END

    SELECT @Ocupados = COUNT(*) 
    FROM PracticaEstudiante 
    WHERE IdVacante = @IdVacante AND IdEstado IN (@IdE_Asig,@IdE_Curso,@IdE_Aprob,@IdE_Fin,@IdE_Rezag);

    IF @Ocupados >= @NumCupos
    BEGIN
        SELECT 0 AS ok, CONCAT('Cupos llenos (',@NumCupos,').') AS message; RETURN;
    END

    IF EXISTS (
        SELECT 1 FROM PracticaEstudiante p
        INNER JOIN Estados e ON e.IdEstado = p.IdEstado
        WHERE p.IdUsuario = @IdUsuario
          AND p.IdVacante <> @IdVacante
          AND e.IdEstado IN (@IdE_Asig,@IdE_Curso,@IdE_Aprob,@IdE_Fin,@IdE_Rezag)
    )
    BEGIN
        SELECT 0 AS ok, 'El estudiante tiene una práctica activa en otra vacante.' AS message; RETURN;
    END

    DECLARE @IdPractica INT, @IdEstadoActual INT, @EstadoActual NVARCHAR(100);
    SELECT TOP 1 @IdPractica = IdPractica, @IdEstadoActual = IdEstado
    FROM PracticaEstudiante
    WHERE IdUsuario = @IdUsuario AND IdVacante = @IdVacante
    ORDER BY IdPractica DESC;

    SELECT @EstadoActual = LTRIM(RTRIM(LOWER(Descripcion))) FROM Estados WHERE IdEstado = @IdEstadoActual;

    IF @IdPractica IS NULL
    BEGIN
        INSERT INTO PracticaEstudiante (IdVacante, IdEstado, IdUsuario, FechaAplicacion)
        VALUES (@IdVacante, @IdE_Proc, @IdUsuario, GETDATE());
        SELECT 1 AS ok, 'Estudiante agregado en "En Proceso de Aplicación".' AS message; RETURN;
    END

    IF @EstadoActual = 'retirada'
    BEGIN
        UPDATE PracticaEstudiante SET IdEstado = @IdE_Proc, FechaAplicacion = GETDATE()
        WHERE IdPractica = @IdPractica;
        SELECT 1 AS ok, 'Reactivado a "En Proceso de Aplicación".' AS message; RETURN;
    END

    IF @EstadoActual = 'en proceso de aplicacion'
    BEGIN
        UPDATE PracticaEstudiante SET IdEstado = @IdE_Asig, FechaAplicacion = GETDATE()
        WHERE IdPractica = @IdPractica;
        SELECT 1 AS ok, 'Actualizado a "Asignada".' AS message; RETURN;
    END

    IF @EstadoActual = 'asignada'
    BEGIN
        SELECT 0 AS ok, 'Ya está asignado en esta vacante.' AS message; RETURN;
    END

    IF @EstadoActual IN ('aprobada','en curso','finalizada','rezagado')
    BEGIN
        SELECT 0 AS ok, CONCAT('No se puede reasignar desde estado "', @EstadoActual, '".') AS message; RETURN;
    END

    -- fallback: volver a "En Proceso"
    UPDATE PracticaEstudiante SET IdEstado = @IdE_Proc, FechaAplicacion = GETDATE()
    WHERE IdPractica = @IdPractica;
    SELECT 1 AS ok, 'Estudiante en "En Proceso de Aplicación".' AS message;
END
GO

/* =========================================================
   POST: Retirar Estudiante (sin IdPractica)
   Controller: POST api/vacantes/retirar-estudiante
   Devuelve (ok, message)
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.RetirarEstudianteSP
    @IdVacante INT,
    @IdUsuario INT,
    @Comentario NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdE_Ret INT = dbo.fn_IdEstado('Retirada');
    IF @IdE_Ret IS NULL
    BEGIN
        SELECT 0 AS ok, 'No existe estado "Retirada".' AS message; RETURN;
    END

    DECLARE @IdPractica INT;
    SELECT TOP 1 @IdPractica = IdPractica
    FROM PracticaEstudiante
    WHERE IdVacante = @IdVacante AND IdUsuario = @IdUsuario
    ORDER BY IdPractica DESC;

    IF @IdPractica IS NULL
    BEGIN
        -- crea registro retirado directo si no existe
        INSERT INTO PracticaEstudiante (IdVacante, IdEstado, IdUsuario, FechaAplicacion)
        VALUES (@IdVacante, @IdE_Ret, @IdUsuario, GETDATE());
        SET @IdPractica = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE PracticaEstudiante SET IdEstado = @IdE_Ret, FechaAplicacion = GETDATE()
        WHERE IdPractica = @IdPractica;
    END

    IF (ISNULL(@Comentario,'') <> '')
    BEGIN
        INSERT INTO ComentariosPractica (Comentario, Fecha, IdUsuario, IdPractica, Nota, Tipo)
        VALUES (@Comentario, GETDATE(), @IdUsuario, @IdPractica, NULL, 'Retiro');
    END

    SELECT 1 AS ok, 'Estudiante retirado (estado "Retirada").' AS message;
END
GO

/* =========================================================
   POST: Desasignar por IdPractica
   Controller: POST api/vacantes/desasignar-practica
   Devuelve (ok, message)
   ========================================================= */
CREATE OR ALTER PROCEDURE dbo.DesasignarPracticaSP
    @IdPractica INT,
    @Comentario NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdE_Ret INT = dbo.fn_IdEstado('Retirada');
    IF @IdE_Ret IS NULL
    BEGIN
        SELECT 0 AS ok, 'No existe estado "Retirada".' AS message; RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM PracticaEstudiante WHERE IdPractica = @IdPractica)
    BEGIN
        SELECT 0 AS ok, 'Práctica no encontrada.' AS message; RETURN;
    END

    UPDATE PracticaEstudiante
    SET IdEstado = @IdE_Ret, FechaAplicacion = GETDATE()
    WHERE IdPractica = @IdPractica;

    IF (ISNULL(@Comentario,'') <> '')
    BEGIN
        DECLARE @IdUsuario INT = (SELECT IdUsuario FROM PracticaEstudiante WHERE IdPractica = @IdPractica);
        INSERT INTO ComentariosPractica (Comentario, Fecha, IdUsuario, IdPractica, Nota, Tipo)
        VALUES (@Comentario, GETDATE(), @IdUsuario, @IdPractica, NULL, 'Desasignación');
    END

    SELECT 1 AS ok, 'Práctica desasignada (Retirada).' AS message;
END
GO
