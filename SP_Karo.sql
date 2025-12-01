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
   --30-11-25
   CREATE OR ALTER PROCEDURE dbo.GetVacantesSP
    @IdEstado       INT = 0,
    @IdEspecialidad INT = 0,
    @IdModalidad    INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    -- Obtener IDs de estados usando función
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

    -- CTE para especialidades
    ;WITH Esp AS (
        SELECT ev.IdVacante,
               STRING_AGG(e.Nombre, ', ') AS EspecialidadNombre
        FROM EspecialidadesVacante ev
        INNER JOIN Especialidades e ON e.IdEspecialidad = ev.IdEspecialidad
        GROUP BY ev.IdVacante
    ),
    -- CTE para postulados
    Post AS (
        SELECT p.IdVacante,
               COUNT(*) AS NumPostulados
        FROM PracticaEstudiante p
        WHERE p.IdEstado IN (@IdE_Asig, @IdE_Curso, @IdE_Aprob, @IdE_Fin, @IdE_Rezag)
        GROUP BY p.IdVacante
    )
    -- SELECT principal
    SELECT
        v.IdVacantePractica            AS IdVacante,
        v.Nombre                        AS Nombre,
        emp.IdEmpresa                   AS IdEmpresa,
        emp.NombreEmpresa              AS EmpresaNombre,
        ISNULL(esp.EspecialidadNombre, '—') AS EspecialidadNombre,
        v.Requisitos                   AS Requerimientos,
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
go

/* =========================================================
   GET: Detalle Vacante
   Controller: GET api/vacantes/detalle/{id}
   ========================================================= */
   USE SIGEP_WEB;
GO
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
        emp.NombreEmpresa AS EmpresaNombre,  -- ✅ CORREGIDO: Ahora trae el nombre
        ISNULL(esp.IdEspecialidad, 0) AS IdEspecialidad,
        v.IdModalidad,
        v.Descripcion,
        v.Requisitos AS Requerimientos,
        v.NumeroCupos AS NumCupos,
        v.FechaMaxAplicacion,
        v.FechaCierre,
        v.Tipo,
        e.Descripcion AS EstadoNombre,
        ISNULL(esp.Especialidades,'—') AS Especialidades,
        ISNULL(u.Ubicacion,'No registrada') AS Ubicacion
    FROM VacantesPractica v
    INNER JOIN Empresas emp ON emp.IdEmpresa = v.IdEmpresa  -- ✅ INNER JOIN para garantizar nombre
    INNER JOIN Estados e    ON e.IdEstado  = v.IdEstado
    LEFT  JOIN Esp esp      ON esp.IdVacante = v.IdVacantePractica
    LEFT  JOIN Ubi u        ON u.IdEmpresa = v.IdEmpresa
    WHERE v.IdVacantePractica = @IdVacante;
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


--16-11-25
USE SIGEP_WEB;
GO
CREATE OR ALTER PROCEDURE GuardarEmpresaSP
(
    @IdEmpresa INT = 0,                -- si es 0 → crear
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

    ------------------------------------------------------
    -- 1. PROVINCIA → buscar o crear
    ------------------------------------------------------
    SELECT @IdProvincia = IdProvincia
    FROM Provincias
    WHERE Nombre = @Provincia;

    IF @IdProvincia IS NULL
    BEGIN
        INSERT INTO Provincias (Nombre) VALUES (@Provincia);
        SET @IdProvincia = SCOPE_IDENTITY();
    END;

    ------------------------------------------------------
    -- 2. CANTON → buscar o crear
    ------------------------------------------------------
    SELECT @IdCanton = IdCanton
    FROM Cantones
    WHERE Nombre = @Canton AND IdProvincia = @IdProvincia;

    IF @IdCanton IS NULL
    BEGIN
        INSERT INTO Cantones (Nombre, IdProvincia)
        VALUES (@Canton, @IdProvincia);

        SET @IdCanton = SCOPE_IDENTITY();
    END;

    ------------------------------------------------------
    -- 3. DISTRITO → buscar o crear
    ------------------------------------------------------
    SELECT @IdDistrito = IdDistrito
    FROM Distritos
    WHERE Nombre = @Distrito AND IdCanton = @IdCanton;

    IF @IdDistrito IS NULL
    BEGIN
        INSERT INTO Distritos (Nombre, IdCanton)
        VALUES (@Distrito, @IdCanton);

        SET @IdDistrito = SCOPE_IDENTITY();
    END;

    ------------------------------------------------------
    -- 4. DIRECCIÓN
    ------------------------------------------------------
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

    ------------------------------------------------------
    -- 5. CREAR O ACTUALIZAR EMPRESA
    ------------------------------------------------------
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

    ------------------------------------------------------
    -- 6. EMAIL
    ------------------------------------------------------
    IF EXISTS(SELECT 1 FROM Emails WHERE IdEmpresa = @IdEmpresaOut)
        UPDATE Emails SET Email = @Email WHERE IdEmpresa = @IdEmpresaOut;
    ELSE
        INSERT INTO Emails (IdEmpresa, Email) VALUES (@IdEmpresaOut, @Email);

    ------------------------------------------------------
    -- 7. TELÉFONO
    ------------------------------------------------------
    IF EXISTS(SELECT 1 FROM Telefonos WHERE IdEmpresa = @IdEmpresaOut)
        UPDATE Telefonos SET Telefono = @Telefono WHERE IdEmpresa = @IdEmpresaOut;
    ELSE
        INSERT INTO Telefonos (IdEmpresa, Telefono) VALUES (@IdEmpresaOut, @Telefono);

END;
GO

USE SIGEP_WEB;
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


USE SIGEP_WEB;
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
    WHERE e.IdEstado = 1;  -- Activo
END
GO

USE SIGEP_WEB;
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

    ------------------------------------------------------
    -- 1. Provincia
    ------------------------------------------------------
    SELECT @IdProvincia = IdProvincia
    FROM Provincias
    WHERE Nombre = @Provincia;

    IF @IdProvincia IS NULL
    BEGIN
        INSERT INTO Provincias (Nombre) VALUES (@Provincia);
        SET @IdProvincia = SCOPE_IDENTITY();
    END;

    ------------------------------------------------------
    -- 2. Cantón
    ------------------------------------------------------
    SELECT @IdCanton = IdCanton
    FROM Cantones
    WHERE Nombre = @Canton AND IdProvincia = @IdProvincia;

    IF @IdCanton IS NULL
    BEGIN
        INSERT INTO Cantones (Nombre, IdProvincia)
        VALUES (@Canton, @IdProvincia);

        SET @IdCanton = SCOPE_IDENTITY();
    END;

    ------------------------------------------------------
    -- 3. Distrito
    ------------------------------------------------------
    SELECT @IdDistrito = IdDistrito
    FROM Distritos
    WHERE Nombre = @Distrito AND IdCanton = @IdCanton;

    IF @IdDistrito IS NULL
    BEGIN
        INSERT INTO Distritos (Nombre, IdCanton)
        VALUES (@Distrito, @IdCanton);

        SET @IdDistrito = SCOPE_IDENTITY();
    END;

    ------------------------------------------------------
    -- 4. Dirección
    ------------------------------------------------------
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

    ------------------------------------------------------
    -- 5. Empresa
    ------------------------------------------------------
    UPDATE Empresas
    SET NombreEmpresa = @NombreEmpresa,
        NombreContacto = @NombreContacto,
        AreasAfinidad = @AreasAfinidad
    WHERE IdEmpresa = @IdEmpresa;

    ------------------------------------------------------
    -- 6. Email
    ------------------------------------------------------
    IF EXISTS(SELECT 1 FROM Emails WHERE IdEmpresa = @IdEmpresa)
        UPDATE Emails SET Email = @Email WHERE IdEmpresa = @IdEmpresa;
    ELSE
        INSERT INTO Emails (IdEmpresa, Email)
        VALUES (@IdEmpresa, @Email);

    ------------------------------------------------------
    -- 7. Teléfono
    ------------------------------------------------------
    IF EXISTS(SELECT 1 FROM Telefonos WHERE IdEmpresa = @IdEmpresa)
        UPDATE Telefonos SET Telefono = @Telefono WHERE IdEmpresa = @IdEmpresa;
    ELSE
        INSERT INTO Telefonos (IdEmpresa, Telefono)
        VALUES (@IdEmpresa, @Telefono);

END
GO


USE SIGEP_WEB;
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

    ------------------------------------------------------
    -- 1. Inactivar empresa
    ------------------------------------------------------
    UPDATE Empresas
    SET IdEstado = @Inactivo
    WHERE IdEmpresa = @IdEmpresa;

    ------------------------------------------------------
    -- 2. Cancelar vacantes asociadas
    ------------------------------------------------------
    UPDATE VacantesPractica
    SET IdEstado = @Cancelado
    WHERE IdEmpresa = @IdEmpresa;
END
GO

--22-11-25

USE SIGEP_WEB
GO

-- =============================================
-- 1. SP PARA OBTENER ESPECIALIDADES
-- =============================================
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

-- =============================================
-- 2. SP PARA ACTUALIZAR ESTADO ACADÉMICO
-- =============================================
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

-- =============================================
-- 3. SP PARA ELIMINAR DOCUMENTO
-- =============================================

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

-- =============================================
-- 4. SP PARA LISTAR ESTUDIANTES
-- =============================================
USE SIGEP_WEB
GO

-- =============================================
-- SP LISTAR ESTUDIANTES
-- =============================================

USE SIGEP_WEB
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
    WHERE u.IdRol = 1 -- Estudiantes
        AND ISNULL(u.IdEstado, 0) != 0 -- Activos
        AND (@EstadoClean IS NULL 
             OR (@EstadoClean = 'Aprobada' AND u.EstadoAcademico = 1)
             OR (@EstadoClean = 'Rezagado' AND u.EstadoAcademico = 0))
        AND (@IdEspecialidadClean IS NULL OR @IdEspecialidadClean = 0 OR 
             EXISTS (SELECT 1 FROM UsuarioEspecialidad ue 
                     WHERE ue.IdUsuario = u.IdUsuario AND ue.IdEspecialidad = @IdEspecialidadClean))
    ORDER BY u.Nombre, u.Apellido1;
END
GO

-- =============================================
-- 5. SP PARA CONSULTAR DETALLE DE ESTUDIANTE
-- =============================================
CREATE OR ALTER PROCEDURE ConsultarEstudianteSP
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;

    -- RESULTSET 1: Información del estudiante
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

    -- RESULTSET 2: Encargados
    SELECT 
        enc.Nombre + ' ' + enc.Apellido1 + ' ' + ISNULL(enc.Apellido2, '') AS Nombre,
        ISNULL((SELECT TOP 1 Telefono FROM Telefonos WHERE IdEncargado = enc.IdEncargado ORDER BY IdTelefono DESC), '') AS Telefono,
        ISNULL(enc.Ocupacion, '') AS Ocupacion
    FROM EstudianteEncargado ee
    INNER JOIN Encargados enc ON ee.IdEncargado = enc.IdEncargado
    WHERE ee.IdUsuario = @IdUsuario;

    -- RESULTSET 3: Documentos
    SELECT 
        IdDocumento,
        Documento
    FROM Documentos
    WHERE IdUsuario = @IdUsuario
    ORDER BY FechaSubida DESC;

    -- RESULTSET 4: Prácticas
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

--27-11-25
-- =============================================
-- STORED PROCEDURES PARA ADMINISTRACIÓN GENERAL
-- =============================================


USE SIGEP_WEB
GO

-- =============================================
-- 1. ConsultarUsuariosSP: Consulta usuarios con filtro opcional por rol
-- =============================================
USE SIGEP_WEB
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


-- =============================================
-- 2. CambiarEstadoUsuarioSP: Cambia el estado de un usuario
-- =============================================
CREATE OR ALTER PROCEDURE CambiarEstadoUsuarioSP
    @IdUsuario INT,
    @NuevoEstado VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @IdEstado INT
    
    -- Determinar IdEstado según el valor del parámetro
    IF @NuevoEstado = 'Activo'
        SET @IdEstado = 1
    ELSE IF @NuevoEstado = 'Inactivo'
        SET @IdEstado = 2
    ELSE
    BEGIN
        -- Estado no válido
        RETURN 0
    END
    
    -- Verificar que el usuario existe
    IF NOT EXISTS (SELECT 1 FROM Usuarios WHERE IdUsuario = @IdUsuario)
    BEGIN
        RETURN 0
    END
    
    -- Actualizar estado
    UPDATE Usuarios
    SET IdEstado = @IdEstado
    WHERE IdUsuario = @IdUsuario
    
    RETURN @@ROWCOUNT
END
GO

-- =============================================
-- 3. CambiarRolUsuarioSP: Cambia el rol de un usuario
-- =============================================
CREATE OR ALTER PROCEDURE CambiarRolUsuarioSP
    @IdUsuario INT,
    @Rol VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @IdRol INT
    
    -- Obtener IdRol según descripción
    SELECT @IdRol = IdRol
    FROM Roles
    WHERE Descripcion = @Rol
    
    IF @IdRol IS NULL
    BEGIN
        RETURN 0
    END
    
    -- Verificar que el usuario existe
    IF NOT EXISTS (SELECT 1 FROM Usuarios WHERE IdUsuario = @IdUsuario)
    BEGIN
        RETURN 0
    END
    
    -- Actualizar rol
    UPDATE Usuarios
    SET IdRol = @IdRol
    WHERE IdUsuario = @IdUsuario
    
    RETURN @@ROWCOUNT
END
GO

-- =============================================
-- 4. ConsultarEspecialidadesSP: Consulta todas las especialidades
-- =============================================
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

-- =============================================
-- 5. CrearEspecialidadSP: Crea una nueva especialidad
-- =============================================
CREATE OR ALTER PROCEDURE CrearEspecialidadSP
    @Nombre VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verificar si ya existe una especialidad con ese nombre
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
    
    -- Insertar nueva especialidad
    INSERT INTO Especialidades (Nombre, IdEstado)
    VALUES (@Nombre, 1)
    
    RETURN @@ROWCOUNT
END
GO

-- =============================================
-- 6. EditarEspecialidadSP: Edita una especialidad existente
-- =============================================
CREATE OR ALTER PROCEDURE EditarEspecialidadSP
    @Id INT,
    @Nombre VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verificar que la especialidad existe
    IF NOT EXISTS (SELECT 1 FROM Especialidades WHERE IdEspecialidad = @Id)
    BEGIN
        RETURN 0
    END
    
    -- Verificar duplicados (excluyendo el mismo registro)
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
    
    -- Actualizar especialidad
    UPDATE Especialidades
    SET Nombre = @Nombre
    WHERE IdEspecialidad = @Id
    
    RETURN @@ROWCOUNT
END
GO

-- =============================================
-- 7. CambiarEstadoEspecialidadSP: Cambia el estado de una especialidad
-- =============================================
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
    
    -- Si se va a desactivar, verificar que no haya usuarios activos relacionados
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
    
    -- Verificar que la especialidad existe
    IF NOT EXISTS (SELECT 1 FROM Especialidades WHERE IdEspecialidad = @Id)
    BEGIN
        RETURN 0
    END
    
    -- Actualizar estado
    UPDATE Especialidades
    SET IdEstado = @IdEstado
    WHERE IdEspecialidad = @Id
    
    RETURN @@ROWCOUNT
END
GO

-- =============================================
-- 8. ConsultarSeccionesSP: Consulta todas las secciones
-- =============================================
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

-- =============================================
-- 9. CrearSeccionSP: Crea una nueva sección
-- =============================================
CREATE OR ALTER PROCEDURE CrearSeccionSP
    @NombreSeccion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verificar si ya existe una sección con ese nombre
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
    
    -- Insertar nueva sección
    INSERT INTO Secciones (Seccion, IdEstado)
    VALUES (@NombreSeccion, 1)  -- 1 = Activo
    
    RETURN @@ROWCOUNT
END
GO

-- =============================================
-- 10. EditarSeccionSP: Edita una sección existente
-- =============================================
CREATE OR ALTER PROCEDURE EditarSeccionSP
    @Id INT,
    @NombreSeccion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verificar que la sección existe
    IF NOT EXISTS (SELECT 1 FROM Secciones WHERE IdSeccion = @Id)
    BEGIN
        RETURN 0
    END
    
    -- Verificar duplicados (excluyendo el mismo registro)
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
    
    -- Actualizar sección
    UPDATE Secciones
    SET Seccion = @NombreSeccion
    WHERE IdSeccion = @Id
    
    RETURN @@ROWCOUNT
END
GO

-- =============================================
-- 11. CambiarEstadoSeccionSP: Cambia el estado de una sección
-- =============================================
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
    
    -- Si se va a desactivar, verificar que no haya usuarios activos relacionados
    IF @IdEstado = 2
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM Usuarios
            WHERE IdSeccion = @Id AND IdEstado = 1
        )
        BEGIN
            RETURN -1  -- Código especial: hay usuarios activos relacionados
        END
    END
    
    -- Verificar que la sección existe
    IF NOT EXISTS (SELECT 1 FROM Secciones WHERE IdSeccion = @Id)
    BEGIN
        RETURN 0
    END
    
    -- Actualizar estado
    UPDATE Secciones
    SET IdEstado = @IdEstado
    WHERE IdSeccion = @Id
    
    RETURN @@ROWCOUNT
END
GO

--28-11-25

USE SIGEP_WEB;
GO

-- =============================================
-- SP 1: Obtener Ubicación de Empresa
-- =============================================
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

PRINT '✅ ObtenerUbicacionEmpresaSP creado';
GO

-- =============================================
-- SP 2: Crear Vacante de Práctica
-- CRÍTICO: Tu BD usa "Requisitos", NO "Requerimientos"
-- =============================================

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

    -- Obtener IdEstado "Activo"
    DECLARE @IdEstadoActivo INT;
    SELECT TOP 1 @IdEstadoActivo = IdEstado 
    FROM Estados 
    WHERE LOWER(LTRIM(RTRIM(Descripcion))) IN ('activo', 'activa')
    ORDER BY IdEstado;

    IF @IdEstadoActivo IS NULL
        SET @IdEstadoActivo = 1;

    -- Validaciones
    IF @NumCupos <= 0 RETURN 0;
    IF @FechaCierre < @FechaMaxAplicacion RETURN 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Insertar vacante
        INSERT INTO VacantesPractica 
        (Nombre, IdEstado, IdEmpresa, Requisitos, FechaMaxAplicacion, 
         NumeroCupos, FechaCierre, IdModalidad, Descripcion, Tipo)
        VALUES 
        (@Nombre, @IdEstadoActivo, @IdEmpresa, @Requerimientos, @FechaMaxAplicacion, 
         @NumCupos, @FechaCierre, @IdModalidad, @Descripcion, NULL);

        DECLARE @NewId INT = SCOPE_IDENTITY();

        -- Insertar especialidad
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

PRINT '✅ CrearVacanteSP creado';
GO

-- =============================================
-- SP 3: Editar Vacante
-- =============================================

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

    IF NOT EXISTS (SELECT 1 FROM VacantesPractica WHERE IdVacantePractica = @IdVacante)
        RETURN 0;

    IF @NumCupos <= 0 RETURN 0;
    IF @FechaCierre < @FechaMaxAplicacion RETURN 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE VacantesPractica
        SET Nombre = @Nombre,
            IdEmpresa = @IdEmpresa,
            Requisitos = @Requerimientos,
            FechaMaxAplicacion = @FechaMaxAplicacion,
            NumeroCupos = @NumCupos,
            FechaCierre = @FechaCierre,
            IdModalidad = @IdModalidad,
            Descripcion = @Descripcion
        WHERE IdVacantePractica = @IdVacante;

        -- Actualizar especialidad
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

PRINT '✅ EditarVacanteSP creado';
GO
-- =============================================
-- SP 4: Eliminar Vacante
-- =============================================
CREATE OR ALTER PROCEDURE dbo.EliminarVacanteSP
    @IdVacante INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM VacantesPractica WHERE IdVacantePractica = @IdVacante)
        RETURN 0;

    -- Verificar dependencias
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

-- =============================================
-- SP 5: Asignar Estudiante
-- =============================================
CREATE OR ALTER PROCEDURE dbo.AsignarEstudianteSP
    @IdVacante INT,
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;

    PRINT '=== INICIO AsignarEstudianteSP ===';
    PRINT '@IdVacante: ' + CAST(@IdVacante AS VARCHAR);
    PRINT '@IdUsuario: ' + CAST(@IdUsuario AS VARCHAR);

    -- Validar vacante
    IF NOT EXISTS (SELECT 1 FROM VacantesPractica WHERE IdVacantePractica = @IdVacante)
    BEGIN
        PRINT 'ERROR: Vacante no existe';
        RETURN 0;
    END

    -- Verificar si ya tiene práctica activa
    IF EXISTS (
        SELECT 1 
        FROM PracticaEstudiante 
        WHERE IdUsuario = @IdUsuario 
        AND IdEstado IN (SELECT IdEstado FROM Estados WHERE LOWER(Descripcion) IN ('activo', 'activa', 'aprobada', 'asignada'))
    )
    BEGIN
        PRINT 'ERROR: Estudiante ya tiene práctica activa';
        RETURN -1;
    END

    -- Verificar cupos
    DECLARE @CuposOcupados INT;
    DECLARE @NumeroCupos INT;

    SELECT @NumeroCupos = NumeroCupos
    FROM VacantesPractica
    WHERE IdVacantePractica = @IdVacante;

    SELECT @CuposOcupados = COUNT(*)
    FROM PracticaEstudiante
    WHERE IdVacante = @IdVacante
    AND IdEstado IN (SELECT IdEstado FROM Estados WHERE LOWER(Descripcion) IN ('activo', 'activa', 'aprobada', 'asignada'));

    PRINT 'Cupos totales: ' + CAST(@NumeroCupos AS VARCHAR);
    PRINT 'Cupos ocupados: ' + CAST(@CuposOcupados AS VARCHAR);

    IF @CuposOcupados >= @NumeroCupos
    BEGIN
        PRINT 'ERROR: No hay cupos disponibles';
        RETURN -2;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Obtener IdEstado "Activo" o "Asignada"
        DECLARE @IdEstadoActivo INT;
        SELECT TOP 1 @IdEstadoActivo = IdEstado 
        FROM Estados 
        WHERE LOWER(LTRIM(RTRIM(Descripcion))) IN ('activo', 'activa', 'asignada', 'aprobada')
        ORDER BY IdEstado;

        IF @IdEstadoActivo IS NULL
            SET @IdEstadoActivo = 1;

        PRINT 'Insertando práctica con IdEstado: ' + CAST(@IdEstadoActivo AS VARCHAR);

        INSERT INTO PracticaEstudiante (IdVacante, IdEstado, IdUsuario, FechaAplicacion)
        VALUES (@IdVacante, @IdEstadoActivo, @IdUsuario, GETDATE());

        COMMIT TRANSACTION;

        PRINT '=== ÉXITO: Estudiante asignado ===';
        RETURN 1;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT 'ERROR: ' + ERROR_MESSAGE();
        RETURN 0;
    END CATCH
END
GO

-- =============================================
-- SP 6: Retirar Estudiante
-- =============================================
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

-- =============================================
-- SP 7: Desasignar Práctica
-- =============================================
CREATE OR ALTER PROCEDURE dbo.DesasignarPracticaSP
    @IdPractica INT,
    @Comentario NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM PracticaEstudiante WHERE IdPractica = @IdPractica)
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

        DECLARE @IdUsuario INT;
        SELECT @IdUsuario = IdUsuario
        FROM PracticaEstudiante
        WHERE IdPractica = @IdPractica;

        UPDATE PracticaEstudiante
        SET IdEstado = @IdEstadoInactivo
        WHERE IdPractica = @IdPractica;

        IF @Comentario IS NOT NULL AND LEN(@Comentario) > 0
        BEGIN
            INSERT INTO ComentariosPractica (Comentario, Fecha, IdUsuario, IdPractica, Tipo)
            VALUES (@Comentario, GETDATE(), @IdUsuario, @IdPractica, 'Desasignación');
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

-- =============================================
-- PRUEBAS DIAGNÓSTICAS
-- =============================================

PRINT '========================================';
PRINT 'PRUEBAS DE DIAGNÓSTICO';
PRINT '========================================';

-- Ver estados disponibles
PRINT '';
PRINT 'Estados disponibles:';
SELECT IdEstado, Descripcion FROM Estados;

-- Ver empresas disponibles
PRINT '';
PRINT 'Empresas disponibles:';
SELECT IdEmpresa, NombreEmpresa, IdDireccion FROM Empresas;

-- Ver especialidades disponibles
PRINT '';
PRINT 'Especialidades disponibles:';
SELECT IdEspecialidad, Nombre FROM Especialidades;

-- Ver modalidades disponibles
PRINT '';
PRINT 'Modalidades disponibles:';
SELECT IdModalidad, Descripcion FROM Modalidades;

PRINT '';
PRINT '========================================';
PRINT 'PRUEBA 1: Obtener ubicación empresa';
PRINT '========================================';
EXEC ObtenerUbicacionEmpresaSP @IdEmpresa = 1;

PRINT '';
PRINT '========================================';
PRINT 'PRUEBA 2: Crear vacante';
PRINT '========================================';
DECLARE @ResultadoCrear INT;
EXEC @ResultadoCrear = CrearVacanteSP 
    @Nombre = 'Práctica de Prueba DIAGNÓSTICO',
    @IdEmpresa = 1,
    @IdEspecialidad = 1,
    @NumCupos = 5,
    @IdModalidad = 1,
    @Requerimientos = 'Prueba de requisitos',
    @Descripcion = 'Prueba de descripción',
    @FechaMaxAplicacion = '2025-12-31',
    @FechaCierre = '2026-01-15';

PRINT 'Resultado CrearVacanteSP: ' + CAST(@ResultadoCrear AS VARCHAR);

IF @ResultadoCrear > 0
BEGIN
    PRINT 'ÉXITO: Vacante creada con ID ' + CAST(@ResultadoCrear AS VARCHAR);
    
    -- Verificar que se guardó
    SELECT * FROM VacantesPractica WHERE IdVacantePractica = @ResultadoCrear;
    SELECT * FROM EspecialidadesVacante WHERE IdVacante = @ResultadoCrear;
END
ELSE
BEGIN
    PRINT 'ERROR: No se pudo crear la vacante';
END

PRINT '';
PRINT '========================================';
PRINT 'FIN DE PRUEBAS';
PRINT '========================================';

SELECT * FROM Empresas;

PRINT '';
PRINT '3. Verificando empresa con IdEmpresa = 1...';
DECLARE @IdEstadoActivo INT;

IF NOT EXISTS (SELECT 1 FROM Empresas WHERE IdEmpresa = 1)
BEGIN
    -- Verificar si existe al menos 1 dirección
    DECLARE @IdDireccionPrueba INT;
    SELECT TOP 1 @IdDireccionPrueba = IdDireccion FROM Direcciones;
    
    IF @IdDireccionPrueba IS NULL
    BEGIN
        -- Crear dirección de prueba si no existe ninguna
        DECLARE @IdDistritoPrueba INT;
        SELECT TOP 1 @IdDistritoPrueba = IdDistrito FROM Distritos;
        
        IF @IdDistritoPrueba IS NOT NULL
        BEGIN
            INSERT INTO Direcciones (IdDistrito, DireccionExacta)
            VALUES (@IdDistritoPrueba, 'Dirección de prueba');
            
            SET @IdDireccionPrueba = SCOPE_IDENTITY();
            PRINT '   ✅ Dirección de prueba creada';
        END
    END
    
    -- Ahora sí, crear la empresa
    SET IDENTITY_INSERT Empresas ON;
    
    INSERT INTO Empresas (IdEmpresa, NombreEmpresa, IdEstado, NombreContacto, IdDireccion, AreasAfinidad)
    VALUES (1, 'Tech Solutions Principal', @IdEstadoActivo, 'Pablo Quiros', @IdDireccionPrueba, 'Informatica');
    
    SET IDENTITY_INSERT Empresas OFF;
    
    PRINT '   ✅ Empresa con IdEmpresa = 1 creada';
END
ELSE
BEGIN
    -- Si existe, asegurarse que esté activa
    UPDATE Empresas 
    SET IdEstado = @IdEstadoActivo 
    WHERE IdEmpresa = 1;
    
    PRINT '   ℹ️ Empresa con IdEmpresa = 1 ya existe (actualizada a activa)';
END

USE SIGEP_WEB;
GO

SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'VacantesPractica';
SELECT TOP 5 * FROM VacantesPractica;
EXEC GetVacantesSP @IdEstado = 0, @IdEspecialidad = 0, @IdModalidad = 0;

SELECT OBJECT_ID('dbo.CrearVacanteSP');

SELECT COLUMN_NAME 
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'VacantesPractica';

DECLARE @Resultado INT;

EXEC @Resultado = CrearVacanteSP 
    @Nombre = 'PRUEBA DESDE SQL',
    @IdEmpresa = 1,
    @IdEspecialidad = 1,
    @NumCupos = 3,
    @IdModalidad = 1,
    @Requerimientos = 'Prueba de requisitos',
    @Descripcion = 'Prueba de descripción',
    @FechaMaxAplicacion = '2025-12-31',
    @FechaCierre = '2026-01-15';

SELECT @Resultado AS IdVacanteCreada;
EXEC DetalleVacanteSP @IdVacante = 5;