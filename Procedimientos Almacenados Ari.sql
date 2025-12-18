USE [SIGEP_WEB]
GO

/****** Object:  StoredProcedure [dbo].[AccionesEncargadoSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[AccionesEncargadoSP]
(
    @IdUsuario    INT,
    @Nombre       VARCHAR(255),
    @Parentesco   VARCHAR(255),
    @Apellido1    VARCHAR(255),
    @Apellido2    VARCHAR(255),
    @Ocupacion    VARCHAR(255),
    @Correo       VARCHAR(255),
    @LugarTrabajo VARCHAR(255),
    @Telefono     VARCHAR(30),
    @Cedula       VARCHAR(30),
    @Encargado    INT    -- IdEncargado cuando es actualización
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdEncargado INT;

    /* ============================
       ACCIÓN 1: INSERTAR ENCARGADO
       ============================ */
    IF (@Encargado = 0)
    BEGIN
        INSERT INTO Encargados
        (
            Cedula,
            Nombre,
            Apellido1,
            Apellido2,
            FechaRegistro,
            Ocupacion,
            LugarTrabajo,
            IdEstado
        )
        VALUES
        (
            @Cedula,
            @Nombre,
            @Apellido1,
            @Apellido2,
            GETDATE(),
            @Ocupacion,
            @LugarTrabajo,
            1
        );

        -- Obtenemos el ID del encargado recién insertado
        SET @IdEncargado = SCOPE_IDENTITY();

        -- Relacionamos el estudiante con el encargado
        INSERT INTO EstudianteEncargado (IdUsuario, IdEncargado, IdEstado, Parentesco)
        VALUES (@IdUsuario, @IdEncargado, 1, @Parentesco);

        -- Insertamos el correo
        INSERT INTO Emails (IdEncargado, Email)
        VALUES (@IdEncargado, @Correo);

        -- Insertamos el teléfono
        INSERT INTO Telefonos (IdEncargado, Telefono)
        VALUES (@IdEncargado, @Telefono);
    END

    /* =============================
       ACCIÓN 2: ACTUALIZAR ENCARGADO
       ============================= */
    IF (@Encargado <> 0)
    BEGIN
        -- Actualizar datos del encargado
        UPDATE Encargados
        SET Cedula       = @Cedula,
            Nombre       = @Nombre,
            Apellido1    = @Apellido1,
            Apellido2    = @Apellido2,
            Ocupacion    = @Ocupacion,
            LugarTrabajo = @LugarTrabajo
        WHERE IdEncargado = @Encargado;

        /* ========== CORREO ========== */
        IF EXISTS (SELECT 1 FROM Emails WHERE IdEncargado = @Encargado)
        BEGIN
            UPDATE Emails
            SET Email = @Correo
            WHERE IdEncargado = @Encargado;
        END
        ELSE
        BEGIN
            INSERT INTO Emails (IdEncargado, Email)
            VALUES (@Encargado, @Correo);
        END

        IF EXISTS (SELECT 1 FROM EstudianteEncargado WHERE IdEncargado = @Encargado AND IdUsuario = @IdUsuario)
        BEGIN
            UPDATE EstudianteEncargado
            SET Parentesco = @Parentesco
            WHERE IdEncargado = @Encargado AND IdUsuario = @IdUsuario;
        END
        ELSE
        BEGIN
            INSERT INTO Emails (IdEncargado, Email)
            VALUES (@Encargado, @Correo);
        END

        /* ========= TELÉFONO ========= */
        IF EXISTS (SELECT 1 FROM Telefonos WHERE IdEncargado = @Encargado)
        BEGIN
            UPDATE Telefonos
            SET Telefono = @Telefono
            WHERE IdEncargado = @Encargado;
        END
        ELSE
        BEGIN
            INSERT INTO Telefonos (IdEncargado, Telefono)
            VALUES (@Encargado, @Telefono);
        END
    END
END;
GO

/****** Object:  StoredProcedure [dbo].[ActualizarContrasennaSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ActualizarContrasennaSP]
    @IdUsuario VARCHAR(100),
    @Contrasenna VARCHAR(100)
AS
BEGIN
    UPDATE Usuarios
    SET Contrasenna = @Contrasenna
    WHERE IdUsuario = @IdUsuario;
END;
GO

/****** Object:  StoredProcedure [dbo].[ActualizarEmpresaSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ActualizarEmpresaSP]
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

drop procedure ObtenerPefilSP


/****** Object:  StoredProcedure [dbo].[ActualizarEstadoAcademicoSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ActualizarEstadoAcademicoSP]
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

/****** Object:  StoredProcedure [dbo].[ActualizarInfoAcademicaSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ActualizarInfoAcademicaSP]
(
    @IdUsuario INT,
    @IdSeccion INT,
    @IdEspecialidad INT
)
AS
BEGIN
    UPDATE Usuarios SET IdSeccion = @IdSeccion WHERE IdUsuario = @IdUsuario;
    UPDATE UsuarioEspecialidad SET IdEspecialidad = @IdEspecialidad WHERE IdUsuario = @IdUsuario;
END;
GO

/****** Object:  StoredProcedure [dbo].[ActualizarInfoMedicaSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ActualizarInfoMedicaSP]
(
    @IdUsuario   INT,
    @Padecimiento VARCHAR(255),
    @Tratamiento  VARCHAR(255),
    @Alergia      VARCHAR(255)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ExisteInfo INT;

    SELECT @ExisteInfo = COUNT(*)
    FROM InformacionMedica
    WHERE IdUsuario = @IdUsuario;

    IF @ExisteInfo > 0
    BEGIN
        UPDATE InformacionMedica
        SET Padecimiento = @Padecimiento,
            Tratamiento  = @Tratamiento,
            Alergia      = @Alergia
        WHERE IdUsuario = @IdUsuario;
    END
    ELSE
    BEGIN
        INSERT INTO InformacionMedica (IdUsuario, Padecimiento, Tratamiento, Alergia)
        VALUES (@IdUsuario, @Padecimiento, @Tratamiento, @Alergia);
    END
END;
GO

/****** Object:  StoredProcedure [dbo].[ActualizarInformacionPersonalSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ActualizarInformacionPersonalSP] 
(
    @IdUsuario       INT,
    @Nombre          VARCHAR(255),
    @Apellido1       VARCHAR(255),
    @Apellido2       VARCHAR(255),
    @Cedula          VARCHAR(255),
    @Telefono        VARCHAR(30),
    @Correo          VARCHAR(100),
    @Provincia       VARCHAR(100),
    @Canton          VARCHAR(100),
    @Distrito        VARCHAR(100),
    @DireccionExacta VARCHAR(MAX),
    @FechaNacimiento DATETIME,
    @Sexo VARCHAR(100),
    @Nacionalidad VARCHAR(255)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ExisteCorreo    INT;
    DECLARE @ExisteTelefono  INT;
    DECLARE @ExisteProvincia INT;
    DECLARE @ExisteDistrito  INT;
    DECLARE @ExisteCanton    INT;
    DECLARE @IdProvincia     INT;
    DECLARE @IdCanton        INT;
    DECLARE @IdDistrito      INT;
    DECLARE @IdDireccion     INT;

    UPDATE Usuarios
    SET Nombre         = @Nombre,
        Apellido1      = @Apellido1,
        Apellido2      = @Apellido2,
        Cedula         = @Cedula,
        FechaNacimiento = @FechaNacimiento,
        Sexo = @Sexo,
        Nacionalidad = @Nacionalidad
    WHERE IdUsuario = @IdUsuario;

    SELECT @ExisteCorreo = COUNT(*)
    FROM Emails
    WHERE IdUsuario = @IdUsuario;

    IF @ExisteCorreo > 0
    BEGIN
        UPDATE Emails
        SET Email = @Correo
        WHERE IdUsuario = @IdUsuario;
    END
    ELSE
    BEGIN
        INSERT INTO Emails (IdUsuario, Email)
        VALUES (@IdUsuario, @Correo);
    END;

    SELECT @ExisteTelefono = COUNT(*)
    FROM Telefonos
    WHERE IdUsuario = @IdUsuario;

    IF @ExisteTelefono > 0
    BEGIN
        UPDATE Telefonos
        SET Telefono = @Telefono
        WHERE IdUsuario = @IdUsuario;
    END
    ELSE
    BEGIN
        INSERT INTO Telefonos (IdUsuario, Telefono)
        VALUES (@IdUsuario, @Telefono);
    END;

    SELECT @ExisteProvincia = COUNT(*)
    FROM Provincias
    WHERE Nombre = @Provincia;

    IF @ExisteProvincia > 0
    BEGIN
        SELECT @IdProvincia = IdProvincia
        FROM Provincias
        WHERE Nombre = @Provincia;
    END
    ELSE
    BEGIN
        INSERT INTO Provincias (Nombre)
        VALUES (@Provincia);

        SELECT @IdProvincia = SCOPE_IDENTITY();
    END;

    SELECT @ExisteCanton = COUNT(*)
    FROM Cantones
    WHERE Nombre = @Canton
      AND IdProvincia = @IdProvincia;

    IF @ExisteCanton > 0
    BEGIN
        SELECT @IdCanton = IdCanton
        FROM Cantones
        WHERE Nombre = @Canton
          AND IdProvincia = @IdProvincia;
    END
    ELSE
    BEGIN
        INSERT INTO Cantones (Nombre, IdProvincia)
        VALUES (@Canton, @IdProvincia);

        SELECT @IdCanton = SCOPE_IDENTITY();
    END;

    SELECT @ExisteDistrito = COUNT(*)
    FROM Distritos
    WHERE Nombre = @Distrito
      AND IdCanton = @IdCanton;

    IF @ExisteDistrito > 0
    BEGIN
        SELECT @IdDistrito = IdDistrito
        FROM Distritos
        WHERE Nombre = @Distrito
          AND IdCanton = @IdCanton;
    END
    ELSE
    BEGIN
        INSERT INTO Distritos (Nombre, IdCanton)
        VALUES (@Distrito, @IdCanton);

        SELECT @IdDistrito = SCOPE_IDENTITY();
    END;

    SELECT @IdDireccion = IdDireccion
    FROM Usuarios
    WHERE IdUsuario = @IdUsuario;

    IF @IdDireccion IS NOT NULL
    BEGIN
        UPDATE Direcciones
        SET DireccionExacta = @DireccionExacta,
            IdDistrito      = @IdDistrito
        WHERE IdDireccion = @IdDireccion;
    END
    ELSE
    BEGIN
        INSERT INTO Direcciones (DireccionExacta, IdDistrito)
        VALUES (@DireccionExacta, @IdDistrito);

        SELECT @IdDireccion = SCOPE_IDENTITY();

        UPDATE Usuarios
        SET IdDireccion = @IdDireccion
        WHERE IdUsuario = @IdUsuario;
    END;
END;
GO

/****** Object:  StoredProcedure [dbo].[AgregarComunicadoSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[AgregarComunicadoSP]
(
    @Nombre VARCHAR(255),
    @Informacion VARCHAR(MAX), 
    @Poblacion VARCHAR(255),
    @FechaLimite DATETIME,
    @IdUsuario INT
)
AS
BEGIN
    INSERT INTO Comunicados (Nombre,IdEstado, Informacion, Fecha, Poblacion, FechaLimite, IdUsuario)
    VALUES (@Nombre, 1, @Informacion, GETDATE(), @Poblacion, @FechaLimite, @IdUsuario);

    SELECT SCOPE_IDENTITY();
END;
GO

/****** Object:  StoredProcedure [dbo].[AsignarEstudianteSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[AsignarEstudianteSP]
    @IdVacante INT,
    @IdUsuario INT,
    @Resultado INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    PRINT '=== INICIO AsignarEstudianteSP ===';
    PRINT '@IdVacante: ' + CAST(@IdVacante AS VARCHAR);
    PRINT '@IdUsuario: ' + CAST(@IdUsuario AS VARCHAR);

    DECLARE @IdEstadoEnProceso   INT;
    DECLARE @IdEstadoAsignada    INT;
    DECLARE @IdEstadoRetirada    INT;
    DECLARE @IdEstadoAprobada    INT;
    DECLARE @IdEstadoEnCurso     INT;
    DECLARE @IdEstadoFinalizada  INT;
    DECLARE @IdEstadoRezagado    INT;

    SELECT @IdEstadoEnProceso  = IdEstado FROM Estados WHERE LOWER(LTRIM(RTRIM(Descripcion))) = 'en proceso de aplicacion';
    SELECT @IdEstadoAsignada   = IdEstado FROM Estados WHERE LOWER(LTRIM(RTRIM(Descripcion))) = 'asignada';
    SELECT @IdEstadoRetirada   = IdEstado FROM Estados WHERE LOWER(LTRIM(RTRIM(Descripcion))) = 'retirada';
    SELECT @IdEstadoAprobada   = IdEstado FROM Estados WHERE LOWER(LTRIM(RTRIM(Descripcion))) = 'aprobada';
    SELECT @IdEstadoEnCurso    = IdEstado FROM Estados WHERE LOWER(LTRIM(RTRIM(Descripcion))) = 'en curso';
    SELECT @IdEstadoFinalizada = IdEstado FROM Estados WHERE LOWER(LTRIM(RTRIM(Descripcion))) = 'finalizada';
    SELECT @IdEstadoRezagado   = IdEstado FROM Estados WHERE LOWER(LTRIM(RTRIM(Descripcion))) = 'rezagado';

    PRINT 'Estados cargados: EnProceso=' + CAST(@IdEstadoEnProceso AS VARCHAR) +
          ', Asignada=' + CAST(@IdEstadoAsignada AS VARCHAR);

    DECLARE @EstadoAcademico BIT = NULL;

    SELECT @EstadoAcademico = EstadoAcademico
    FROM dbo.Usuarios
    WHERE IdUsuario = @IdUsuario;

    IF @EstadoAcademico IS NULL
    BEGIN
        PRINT 'ERROR: Usuario no existe';
        SET @Resultado = -6;
        RETURN;
    END

    IF @EstadoAcademico = 0
    BEGIN
        PRINT 'ERROR: Estudiante rezagado (EstadoAcademico=0). No se permite asignar.';
        SET @Resultado = -5;
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM VacantesPractica WHERE IdVacantePractica = @IdVacante)
    BEGIN
        PRINT 'ERROR: Vacante no existe';
        SET @Resultado = 0;
        RETURN;
    END

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

/****** Object:  StoredProcedure [dbo].[CambiarEstadoComunicadoSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[CambiarEstadoComunicadoSP](@IdComunicado INT, @IdEstado INT)
AS
BEGIN
    UPDATE Comunicados SET IdEstado = @IdEstado WHERE IdComunicado = @IdComunicado;
END;
GO

/****** Object:  StoredProcedure [dbo].[CambiarEstadoDocumentoSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[CambiarEstadoDocumentoSP](@IdComunicado INT, @IdEstado INT)
AS
BEGIN
    UPDATE Comunicados SET IdEstado = @IdEstado WHERE IdComunicado = @IdComunicado;
END;
GO

/****** Object:  StoredProcedure [dbo].[CambiarEstadoEspecialidadSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[CambiarEstadoEspecialidadSP]
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

/****** Object:  StoredProcedure [dbo].[CambiarEstadoSeccionSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[CambiarEstadoSeccionSP]
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

/****** Object:  StoredProcedure [dbo].[CambiarEstadoUsuarioSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[CambiarEstadoUsuarioSP]
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

/****** Object:  StoredProcedure [dbo].[CambiarRolUsuarioSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[CambiarRolUsuarioSP]
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

/****** Object:  StoredProcedure [dbo].[ConsultarEmpresaSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ConsultarEmpresaSP]
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

/****** Object:  StoredProcedure [dbo].[ConsultarEspecialidadesSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ConsultarEspecialidadesSP]
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

/****** Object:  StoredProcedure [dbo].[ConsultarEstudianteSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ConsultarEstudianteSP]
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

/****** Object:  StoredProcedure [dbo].[ConsultarSeccionesSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ConsultarSeccionesSP]
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

/****** Object:  StoredProcedure [dbo].[ConsultarUsuariosSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ConsultarUsuariosSP]
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

/****** Object:  StoredProcedure [dbo].[CrearEspecialidadSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[CrearEspecialidadSP]
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

/****** Object:  StoredProcedure [dbo].[CrearSeccionSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[CrearSeccionSP]
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

/****** Object:  StoredProcedure [dbo].[CrearVacanteSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[CrearVacanteSP]
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
        (@Nombre, @IdEstadoActivo, @IdEmpresa, @Requisitos, @FechaMaxAplicacion,
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

/****** Object:  StoredProcedure [dbo].[DesactivarDocumentoSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[DesactivarDocumentoSP](@IdComunicado INT)
AS
BEGIN
    UPDATE Comunicados SET IdEstado = 2 WHERE IdComunicado = @IdComunicado;
END;
GO

/****** Object:  StoredProcedure [dbo].[DesasignarPracticaSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[DesasignarPracticaSP]
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
        PRINT '? ERROR: La práctica con IdPractica=' + CAST(@IdPractica AS VARCHAR) + ' NO EXISTE';
        SET @Resultado = 0;
        RETURN;
    END

    PRINT '? Práctica encontrada';

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
            PRINT '? ERROR CRÍTICO: No existe ningún estado válido (Retirada/Inactivo)';
            PRINT 'Estados disponibles en la tabla:';
            
            DECLARE @EstadosDisponibles NVARCHAR(MAX);
            SELECT @EstadosDisponibles = STRING_AGG(CAST(IdEstado AS VARCHAR) + '=' + Descripcion, ', ')
            FROM Estados;
            
            PRINT @EstadosDisponibles;

            ROLLBACK TRANSACTION;
            SET @Resultado = -2;
            RETURN;
        END

        PRINT '? Estado a usar: IdEstado=' + CAST(@IdEstadoRetirada AS VARCHAR);

        DECLARE @IdUsuario INT;
        SELECT @IdUsuario = IdUsuario
        FROM PracticaEstudiante
        WHERE IdPractica = @IdPractica;

        PRINT 'IdUsuario: ' + CAST(@IdUsuario AS VARCHAR);

        UPDATE PracticaEstudiante
        SET IdEstado = @IdEstadoRetirada
        WHERE IdPractica = @IdPractica;

        PRINT '? Estado de práctica actualizado';

        DECLARE @ComentarioLimpio NVARCHAR(MAX) = LTRIM(RTRIM(@Comentario));

        IF @ComentarioLimpio IS NOT NULL AND LEN(@ComentarioLimpio) > 0
        BEGIN
            INSERT INTO ComentariosPractica (Comentario, Fecha, IdUsuario, IdPractica, Tipo)
            VALUES (@ComentarioLimpio, GETDATE(), @IdUsuario, @IdPractica, 'Desasignación');

            PRINT '? Comentario insertado: "' + LEFT(@ComentarioLimpio, 50) + '..."';
        END
        ELSE
        BEGIN
            PRINT '?? AVISO: No se insertó comentario (vacío o NULL)';
        END

        COMMIT TRANSACTION;

        PRINT '';
        PRINT '========================================';
        PRINT '=== ? COMMIT EXITOSO ===';
        PRINT '========================================';

        SET @Resultado = 1;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT '';
        PRINT '========================================';
        PRINT '=== ? ERROR EN CATCH ===';
        PRINT '========================================';
        PRINT 'ERROR_MESSAGE: ' + ERROR_MESSAGE();
        PRINT 'ERROR_NUMBER: ' + CAST(ERROR_NUMBER() AS VARCHAR);
        PRINT 'ERROR LINE: ' + CAST(ERROR_LINE() AS VARCHAR);
        PRINT 'ERROR_SEVERITY: ' + CAST(ERROR_SEVERITY() AS VARCHAR);
        PRINT 'ERROR_STATE: ' + CAST(ERROR_STATE() AS VARCHAR);
        
        SET @Resultado = 0;
    END CATCH
END
GO

/****** Object:  StoredProcedure [dbo].[DetalleVacanteSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[DetalleVacanteSP]
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

/****** Object:  StoredProcedure [dbo].[EditarComunicadoSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[EditarComunicadoSP]
(
    @IdComunicado INT,
    @Nombre VARCHAR(255), 
    @Informacion VARCHAR(MAX),
    @FechaLimite DATETIME,
    @Poblacion VARCHAR(255)
)
AS
BEGIN
    UPDATE Comunicados
    SET Nombre = @Nombre,
        Informacion = @Informacion,
        FechaLimite = @FechaLimite,
        Poblacion = @Poblacion
    WHERE IdComunicado = @IdComunicado;
END;
GO

/****** Object:  StoredProcedure [dbo].[EditarEspecialidadSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[EditarEspecialidadSP]
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

/****** Object:  StoredProcedure [dbo].[EditarSeccionSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[EditarSeccionSP]
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

/****** Object:  StoredProcedure [dbo].[EditarVacanteSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[EditarVacanteSP]
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

/****** Object:  StoredProcedure [dbo].[EliminarDocumentoSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[EliminarDocumentoSP]
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

/****** Object:  StoredProcedure [dbo].[EliminarEmpresaSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[EliminarEmpresaSP]
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

/****** Object:  StoredProcedure [dbo].[EliminarVacanteSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[EliminarVacanteSP]
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

/****** Object:  StoredProcedure [dbo].[FinalizarPracticasSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[FinalizarPracticasSP]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @IdAprobada   INT,
        @IdRezagada   INT,
        @IdFinalizada INT,
        @IdEnCurso    INT,
        @IdArchivado  INT;

    SELECT @IdAprobada   = IdEstado FROM Estados WHERE Descripcion = 'Aprobada';
    SELECT @IdRezagada   = IdEstado FROM Estados WHERE Descripcion = 'Rezagada';
    SELECT @IdFinalizada = IdEstado FROM Estados WHERE Descripcion = 'Finalizada';
    SELECT @IdEnCurso    = IdEstado FROM Estados WHERE Descripcion = 'En Curso';
    SELECT @IdArchivado  = IdEstado FROM Estados WHERE Descripcion = 'Archivado';

    BEGIN TRY
        BEGIN TRAN;

        UPDATE pe
        SET pe.IdEstado = 
            CASE 
                WHEN n.NotaFinal >= 70 THEN @IdFinalizada
                ELSE @IdRezagada
            END
        FROM PracticaEstudiante pe
        INNER JOIN NotasEstudiantesTB n 
            ON n.IdUsuario = pe.IdUsuario
        WHERE pe.IdEstado = @IdEnCurso;

        UPDATE u
        SET u.IdEstado = 2,
            u.FechaEgreso = GETDATE()
        FROM Usuarios u
        WHERE EXISTS (
            SELECT 1
            FROM PracticaEstudiante p
            WHERE p.IdUsuario = u.IdUsuario
              AND p.IdEstado = @IdFinalizada
        );

        UPDATE VacantesPractica
        SET IdEstado = @IdArchivado;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO

/****** Object:  StoredProcedure [dbo].[GetVacantesSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[GetVacantesSP]
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
        v.Requisitos                   AS Requisitos,
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

/****** Object:  StoredProcedure [dbo].[GuardarComentarioEvaluacionSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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

/****** Object:  StoredProcedure [dbo].[GuardarDocumentoEvaluacionSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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

/****** Object:  StoredProcedure [dbo].[GuardarDocumentosComunicadoSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[GuardarDocumentosComunicadoSP]
(
    @IdComunicado INT,
    @NombreArchivo VARCHAR(255),
    @Tipo VARCHAR(100)
)
AS
BEGIN
    INSERT INTO Documentos (Documento, Tipo, IdComunicado, FechaSubida)
    VALUES (@NombreArchivo, @Tipo, @IdComunicado, GETDATE());
END;
GO

/****** Object:  StoredProcedure [dbo].[GuardarEmpresaSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[GuardarEmpresaSP]
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

/****** Object:  StoredProcedure [dbo].[GuardarNotaEstudianteSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
        
        IF EXISTS (SELECT 1 FROM NotasEstudiantesTB WHERE IdUsuario = @IdUsuario)
        BEGIN
            UPDATE NotasEstudiantesTB
            SET Nota1 = @Nota1,
                Nota2 = @Nota2,
                NotaFinal = @NotaFinal,
                FechaActualizacion = GETDATE(),
                IdCoordinador = @IdCoordinador
            WHERE IdUsuario = @IdUsuario;
        END
        ELSE
        BEGIN
            INSERT INTO NotasEstudiantesTB (IdUsuario, Nota1, Nota2, NotaFinal, FechaRegistro, IdCoordinador)
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

/****** Object:  StoredProcedure [dbo].[IndicadoresDashboard]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[IndicadoresDashboard]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        (SELECT COUNT(*)
         FROM Usuarios
         WHERE IdRol = 1
           AND IdEstado = 1) AS EstudiantesActivos,

        (SELECT COUNT(DISTINCT PE.IdUsuario)
         FROM PracticaEstudiante PE
         INNER JOIN Usuarios U ON U.IdUsuario = PE.IdUsuario
         WHERE U.IdRol = 1
           AND U.IdEstado = 1
           AND PE.IdEstado = 5) AS EstudiantesConPractica,

        (SELECT COUNT(*)
         FROM Usuarios U
         WHERE U.IdRol = 1
           AND U.IdEstado = 1
           AND NOT EXISTS (
               SELECT 1
               FROM PracticaEstudiante PE
               WHERE PE.IdUsuario = U.IdUsuario
                 AND PE.IdEstado = 5
           )) AS EstudiantesSinPractica,

        (SELECT COUNT(*)
         FROM PracticaEstudiante
         WHERE IdEstado = 5) AS PracticasAsignadas,

        (SELECT COUNT(*)
         FROM PracticaEstudiante
         WHERE IdEstado = 8) AS PracticasFinalizadas,

        (SELECT COUNT(*)
         FROM Empresas
         WHERE IdEstado = 1) AS EmpresasRegistradas;
END;
GO

/****** Object:  StoredProcedure [dbo].[IniciarPracticasSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[IniciarPracticasSP]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @IdAsignada   INT,
        @IdEnCurso    INT,
        @IdRetirada   INT,
        @IdFinalizada INT,
        @IdAprobada   INT,
        @IdRezagada   INT;

    SELECT @IdAsignada   = IdEstado FROM Estados WHERE Descripcion = 'Asignada';
    SELECT @IdEnCurso    = IdEstado FROM Estados WHERE Descripcion = 'En Curso';
    SELECT @IdRetirada   = IdEstado FROM Estados WHERE Descripcion = 'Retirada';
    SELECT @IdFinalizada = IdEstado FROM Estados WHERE Descripcion = 'Finalizada';
    SELECT @IdAprobada   = IdEstado FROM Estados WHERE Descripcion = 'Aprobada';
    SELECT @IdRezagada   = IdEstado FROM Estados WHERE Descripcion = 'Rezagada';

    BEGIN TRY
        BEGIN TRAN;

        UPDATE p
        SET p.IdEstado = @IdEnCurso
        FROM PracticaEstudiante p
        INNER JOIN Usuarios u ON u.IdUsuario = p.IdUsuario
        WHERE p.IdEstado = @IdAsignada
          AND u.EstadoAcademico = 1;

        UPDATE p
        SET p.IdEstado = @IdRetirada
        FROM PracticaEstudiante p
        WHERE p.IdEstado NOT IN (
            @IdEnCurso,
            @IdFinalizada,
            @IdAprobada,
            @IdRezagada
        );

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO

/****** Object:  StoredProcedure [dbo].[ListarEmpresasSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ListarEmpresasSP]
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

/****** Object:  StoredProcedure [dbo].[ListarEstudiantesSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ListarEstudiantesSP]
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

/****** Object:  StoredProcedure [dbo].[LoginSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[LoginSP]
    @CEDULA VARCHAR(100),
    @CONTRASENNA VARCHAR(100)
AS
BEGIN
    SELECT 
        U.IdUsuario,
        U.Nombre,
        U.Apellido1, 
        U.Apellido2,
        U.Cedula,
        U.IdRol,
        U.IdEstado,
        S.Seccion,
        E.Nombre AS Especialidad
    FROM dbo.Usuarios U 
    INNER JOIN dbo.Secciones S 
        ON U.IdSeccion = S.IdSeccion
    INNER JOIN dbo.UsuarioEspecialidad UE
        ON UE.IdUsuario = U.IdUsuario
    INNER JOIN dbo.Especialidades E
        ON UE.IdEspecialidad = E.IdEspecialidad
    WHERE U.Cedula = @CEDULA
      AND Contrasenna = @CONTRASENNA AND U.IdEstado = 1;
END;
GO

/****** Object:  StoredProcedure [dbo].[ObtenerCedulaUsuarioSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ObtenerCedulaUsuarioSP]
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT Cedula
    FROM Usuarios
    WHERE IdUsuario = @IdUsuario;
END
GO

/****** Object:  StoredProcedure [dbo].[ObtenerComentariosEstudianteSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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

/****** Object:  StoredProcedure [dbo].[ObtenerComunicadosSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ObtenerComunicadosSP]
(
    @Poblacion VARCHAR(255)
)
AS
BEGIN
    SET NOCOUNT ON;

    IF (@Poblacion = 'Administrativos')
    BEGIN
        SELECT 
            C.IdComunicado,
            C.Nombre,
            C.IdEstado,
            C.Informacion,
            C.Fecha,
            C.Poblacion,
            C.FechaLimite,
            C.IdUsuario,
            CONCAT(U.Nombre, ' ', U.Apellido1, ' ', U.Apellido2) AS PublicadoPor
        FROM Comunicados C
        INNER JOIN Usuarios U
            ON C.IdUsuario = U.IdUsuario
    END
    ELSE
    BEGIN
        SELECT 
            C.IdComunicado,
            C.Nombre,
            C.IdEstado,
            C.Informacion,
            C.Fecha,
            C.Poblacion,
            C.FechaLimite,
            C.IdUsuario,
            CONCAT(U.Nombre, ' ', U.Apellido1, ' ', U.Apellido2) AS PublicadoPor
        FROM Comunicados C
        INNER JOIN Usuarios U
            ON C.IdUsuario = U.IdUsuario
        WHERE 
            C.IdEstado = 1
            AND (
                C.Poblacion = @Poblacion
                OR C.Poblacion = 'General'
            );
    END
END;
GO

/****** Object:  StoredProcedure [dbo].[ObtenerDetallesComunicadoSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ObtenerDetallesComunicadoSP] (@IdComunicado INT)
AS
BEGIN
    SELECT 
        C.IdComunicado,
        C.Nombre,
        C.IdEstado,
        C.Informacion,
        C.Fecha,
        C.Poblacion,
        C.FechaLimite,
        C.IdUsuario,
        CONCAT(U.Nombre, ' ', U.Apellido1, ' ', U.Apellido2) AS PublicadoPor
    FROM Comunicados C
    INNER JOIN Usuarios U
        ON C.IdUsuario = U.IdUsuario
    WHERE C.IdComunicado = @IdComunicado
END;
GO

/****** Object:  StoredProcedure [dbo].[ObtenerDocumentoPorIdSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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

/****** Object:  StoredProcedure [dbo].[ObtenerDocumentosComunicadoSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ObtenerDocumentosComunicadoSP]
(
    @IdComunicado INT
)
AS
BEGIN
    SELECT IdDocumento, Documento, Tipo, IdUsuario, FechaSubida, IdComunicado
    FROM Documentos
    WHERE IdComunicado = @IdComunicado;
END;
GO

/****** Object:  StoredProcedure [dbo].[ObtenerDocumentosEvaluacionSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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

/****** Object:  StoredProcedure [dbo].[ObtenerDocumentosPerfilSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ObtenerDocumentosPerfilSP]
(
    @IdUsuario INT
)
AS
BEGIN
    SELECT [IdDocumento],[Documento],[Tipo],[IdUsuario],[FechaSubida]
    FROM [dbo].[Documentos]
    WHERE IdUsuario = @IdUsuario;
END
GO

/****** Object:  StoredProcedure [dbo].[ObtenerEmailsSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ObtenerEmailsSP] (@Destinatario VARCHAR(255))
AS
BEGIN
    IF @Destinatario = 'Estudiantes'
    BEGIN
        SELECT U.IdUsuario, U.Nombre, U.Apellido1, U.Apellido2,
               E.Email, E.IdEmail, R.IdRol, R.Descripcion AS Rol
        FROM Usuarios U
        INNER JOIN Emails E ON U.IdUsuario = E.IdUsuario
        INNER JOIN Roles R ON R.IdRol = U.IdRol
        WHERE U.IdEstado = 1
          AND U.IdRol = 1;
    END
    ELSE IF @Destinatario = 'Administrativos'
    BEGIN
        SELECT U.IdUsuario, U.Nombre, U.Apellido1, U.Apellido2,
               E.Email, E.IdEmail, R.IdRol, R.Descripcion AS Rol
        FROM Usuarios U
        INNER JOIN Emails E ON U.IdUsuario = E.IdUsuario
        INNER JOIN Roles R ON R.IdRol = U.IdRol
        WHERE U.IdEstado = 1
          AND U.IdRol = 2;
    END
    ELSE
    BEGIN
        SELECT U.IdUsuario, U.Nombre, U.Apellido1, U.Apellido2,
               E.Email, E.IdEmail, R.IdRol, R.Descripcion AS Rol
        FROM Usuarios U
        INNER JOIN Emails E ON U.IdUsuario = E.IdUsuario
        INNER JOIN Roles R ON R.IdRol = U.IdRol
        WHERE U.IdEstado = 1;
    END
END;
GO

/****** Object:  StoredProcedure [dbo].[ObtenerEncargadoSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ObtenerEncargadoSP](@IdEncargado INT, @IdUsuario INT)
AS
BEGIN
    SELECT E.Cedula, E.Nombre, E.Apellido1, E.Apellido2, E.Ocupacion,
           E.LugarTrabajo, C.Email as Correo, E.IdEncargado, T.Telefono, EE.Parentesco
    FROM Encargados E
    INNER JOIN Emails C
        ON E.IdEncargado = C.IdEncargado
    INNER JOIN Telefonos T
        ON E.IdEncargado = T.IdEncargado
    INNER JOIN EstudianteEncargado EE
        ON EE.IdEncargado = E.IdEncargado
    WHERE E.IdEstado = 1 AND E.IdEncargado = @IdEncargado AND EE.IdUsuario = @IdUsuario;
END;
GO

/****** Object:  StoredProcedure [dbo].[ObtenerEncargadosSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ObtenerEncargadosSP]
(
    @IdUsuario INT
)
AS
BEGIN
    SELECT E.Cedula, E.Nombre, E.Apellido1, E.Apellido2, E.FechaRegistro, E.Ocupacion, E.LugarTrabajo,
           E.IdEncargado, EE.IdEstado, EE.Parentesco, C.Email as Correo, T.Telefono
    FROM Encargados E
    INNER JOIN EstudianteEncargado EE
        ON E.IdEncargado = EE.IdEncargado
    LEFT JOIN Emails C
        ON C.IdEncargado = E.IdEncargado
    LEFT JOIN Telefonos T
        ON T.IdEncargado = E.IdEncargado
    WHERE EE.IdUsuario = @IdUsuario
      AND EE.IdEstado = 1;
END;
GO

/****** Object:  StoredProcedure [dbo].[ObtenerEspecialidadesSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ObtenerEspecialidadesSP]
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

/****** Object:  StoredProcedure [dbo].[ObtenerEstudiantesAsignarSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ObtenerEstudiantesAsignarSP]
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

/****** Object:  StoredProcedure [dbo].[ObtenerEstudiantesParaEvaluacionSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
    LEFT JOIN NotasEstudiantesTB n ON u.IdUsuario = n.IdUsuario
    INNER JOIN Estados est ON p.IdEstado = est.IdEstado
    WHERE u.IdRol = 1  
        AND u.IdEstado = 1 
        AND est.Descripcion IN ('En Curso', 'Rezagado', 'Aprobada', 'Finalizada')
    ORDER BY u.Nombre, u.Apellido1;
END
GO

/****** Object:  StoredProcedure [dbo].[ObtenerHistoricoSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ObtenerHistoricoSP]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.IdPractica,
        p.IdVacante,
        u.IdUsuario,
        u.Cedula,
        NombreCompleto = CONCAT(u.Nombre,' ',u.Apellido1,' ',u.Apellido2),
        EstadoDescripcion = e.Descripcion,
        em.NombreEmpresa as Empresa,
        em.IdEmpresa,
        es.Nombre as Especialidad, 
        t.Telefono as Telefono
    FROM PracticaEstudiante p
    INNER JOIN Usuarios u ON u.IdUsuario = p.IdUsuario
    INNER JOIN Estados  e ON e.IdEstado  = p.IdEstado
    INNER JOIN VacantesPractica v on v.IdVacantePractica = p.IdVacante
    INNER JOIN Empresas em on em.IdEmpresa = v.IdEmpresa
    INNER JOIN UsuarioEspecialidad ue on ue.IdUsuario = u.IdUsuario
    INNER JOIN Especialidades es on es.IdEspecialidad = ue.IdEspecialidad
    LEFT JOIN Telefonos T on T.IdUsuario = U.IdUsuario
    WHERE YEAR(p.FechaAplicacion) <> YEAR(GETDATE())
    ORDER BY p.IdPractica DESC;
END
GO

/****** Object:  StoredProcedure [dbo].[ObtenerNombreCompletoUsuarioSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ObtenerNombreCompletoUsuarioSP]
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT Nombre + ' ' + Apellido1 AS NombreCompleto
    FROM Usuarios
    WHERE IdUsuario = @IdUsuario;
END
GO


/****** Object:  StoredProcedure [dbo].[ObtenerPostulacionesSP]    Script Date: 12/16/2025 9:34:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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

/****** Object:  StoredProcedure [dbo].[ObtenerPerfilSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ObtenerPerfilSP]
(
    @IdUsuario INT
)
AS
BEGIN
    SELECT U.IdUsuario, U.Cedula, U.Nombre, U.Apellido1, U.Apellido2, U.FechaNacimiento,
           U.FechaRegistro, U.FechaEgreso, U.IdRol, U.IdSeccion, U.IdEstado, E.Email AS Correo, T.Telefono, D.DireccionExacta,
           D.IdDistrito, D.IdDireccion, DD.Nombre as Distrito, C.Nombre AS Canton, C.IdCanton, P.Nombre As Provincia, P.IdProvincia,
           IM.Padecimiento, IM.Tratamiento, IM.Alergia, IM.IdInformacionMedica, UE.IdEspecialidad, U.Sexo, U.Nacionalidad
    FROM Usuarios U
    LEFT JOIN Emails E ON U.IdUsuario = E.IdUsuario
    LEFT JOIN Telefonos T ON U.IdUsuario = T.IdUsuario
    LEFT JOIN Direcciones D ON U.IdDireccion = D.IdDireccion
    LEFT JOIN Distritos DD ON D.IdDistrito = DD.IdDistrito
    LEFT JOIN Cantones C ON DD.IdCanton = C.IdCanton
    LEFT JOIN Provincias P ON C.IdProvincia = P.IdProvincia
    LEFT JOIN InformacionMedica IM ON U.IdUsuario = IM.IdUsuario
    LEFT JOIN UsuarioEspecialidad UE ON U.IdUsuario = UE.IdUsuario
    WHERE u.IdUsuario = @IdUsuario;
END
GO

/****** Object:  StoredProcedure [dbo].[ObtenerPostulacionesPracticasSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ObtenerPostulacionesPracticasSP]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.IdPractica,
        p.IdVacante,
        u.IdUsuario,
        u.Cedula,
        NombreCompleto = CONCAT(u.Nombre,' ',u.Apellido1,' ',u.Apellido2),
        EstadoDescripcion = e.Descripcion,
        em.NombreEmpresa AS Empresa,
        em.IdEmpresa,
        es.Nombre AS Especialidad, 
        t.Telefono AS Telefono,
        NotaFinal = CASE 
            WHEN e.Descripcion IN ('En Curso', 'Aprobada', 'Rezagada', 'Finalizada')
                THEN CAST(n.NotaFinal AS VARCHAR(10))
            ELSE 'No Aplica'
        END
    FROM PracticaEstudiante p
    INNER JOIN Usuarios u ON u.IdUsuario = p.IdUsuario
    INNER JOIN Estados e ON e.IdEstado = p.IdEstado
    INNER JOIN VacantesPractica v ON v.IdVacantePractica = p.IdVacante
    INNER JOIN Empresas em ON em.IdEmpresa = v.IdEmpresa
    INNER JOIN UsuarioEspecialidad ue ON ue.IdUsuario = u.IdUsuario
    INNER JOIN Especialidades es ON es.IdEspecialidad = ue.IdEspecialidad
    LEFT JOIN Telefonos t ON t.IdUsuario = u.IdUsuario
    LEFT JOIN NotasEstudiantes n ON n.IdUsuario = u.IdUsuario
    WHERE YEAR(p.FechaAplicacion) = YEAR(GETDATE()) 
    ORDER BY p.IdPractica DESC;
END
GO

/****** Object:  StoredProcedure [dbo].[ObtenerPostulacionesSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ObtenerPostulacionesSP]
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

/****** Object:  StoredProcedure [dbo].[ObtenerSeccionesSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ObtenerSeccionesSP] 
AS
BEGIN
    SELECT IdSeccion, Seccion
    FROM Secciones WHERE IdEstado = 1;
END;
GO

/****** Object:  StoredProcedure [dbo].[ObtenerUbicacionEmpresaSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ObtenerUbicacionEmpresaSP]
    @IdEmpresa INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @IdAprobada   INT,
        @IdRezagada   INT,
        @IdFinalizada INT,
        @IdEnCurso    INT,
        @IdArchivado  INT;

    SELECT @IdAprobada   = IdEstado FROM Estados WHERE Descripcion = 'Aprobada';
    SELECT @IdRezagada   = IdEstado FROM Estados WHERE Descripcion = 'Rezagada';
    SELECT @IdFinalizada = IdEstado FROM Estados WHERE Descripcion = 'Finalizada';
    SELECT @IdEnCurso    = IdEstado FROM Estados WHERE Descripcion = 'En Curso';
    SELECT @IdArchivado  = IdEstado FROM Estados WHERE Descripcion = 'Archivado';

    BEGIN TRY
        BEGIN TRAN;

        -------------------------------------------------
        -- 1. En Curso → Finalizada / Rezagada
        -------------------------------------------------
        UPDATE pe
        SET pe.IdEstado = 
            CASE 
                WHEN n.NotaFinal >= 70 THEN @IdFinalizada
                ELSE @IdRezagada
            END
        FROM PracticaEstudiante pe
        INNER JOIN NotasEstudiantes n 
            ON n.IdUsuario = pe.IdUsuario
        WHERE pe.IdEstado = @IdEnCurso;

        -------------------------------------------------
        -- 2. Usuarios con práctica finalizada → Inactivo
        -------------------------------------------------
        UPDATE u
        SET u.IdEstado = 2,
            u.FechaEgreso = GETDATE()
        FROM Usuarios u
        WHERE EXISTS (
            SELECT 1
            FROM PracticaEstudiante p
            WHERE p.IdUsuario = u.IdUsuario
              AND p.IdEstado = @IdFinalizada
        );

        -------------------------------------------------
        -- 3. TODAS las vacantes → Archivadas
        -------------------------------------------------
        UPDATE VacantesPractica
        SET IdEstado = @IdArchivado;

/****** Object:  StoredProcedure [dbo].[ObtenerVacantesAsignarSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ObtenerVacantesAsignarSP]
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;

    -------------------------------------------------
    -- Especialidades del estudiante
    -------------------------------------------------
    DECLARE @EspecialidadesEst TABLE (IdEspecialidad INT);

    INSERT INTO @EspecialidadesEst (IdEspecialidad)
    SELECT DISTINCT IdEspecialidad
    FROM UsuarioEspecialidad
    WHERE IdUsuario = @IdUsuario
      AND IdEstado = 1;

    -------------------------------------------------
    -- Estados que ocupan cupo
    -------------------------------------------------
    DECLARE @EstadosOcupados TABLE (IdEstado INT);

    INSERT INTO @EstadosOcupados (IdEstado)
    SELECT IdEstado
    FROM Estados
    WHERE LOWER(LTRIM(RTRIM(Descripcion))) IN (
        'asignada',
        'en curso',
        'aprobada',
        'finalizada',
        'rezagada'
    );

    -------------------------------------------------
    -- Vacantes posibles para asignar
    -------------------------------------------------
    SELECT
        v.IdVacantePractica AS IdVacante,
        LTRIM(RTRIM(v.Nombre)) AS Nombre,
        emp.NombreEmpresa,

        ISNULL((
            SELECT TOP 1 esp.Nombre
            FROM EspecialidadesVacante ev
            INNER JOIN Especialidades esp 
                ON esp.IdEspecialidad = ev.IdEspecialidad
            WHERE ev.IdVacante = v.IdVacantePractica
              AND ev.IdEspecialidad IN (
                  SELECT IdEspecialidad FROM @EspecialidadesEst
              )
        ), '—') AS Especialidad,

        v.NumeroCupos as NumCupos,

        (
            SELECT COUNT(*)
            FROM PracticaEstudiante p
            WHERE p.IdVacante = v.IdVacantePractica
              AND p.IdEstado IN (
                  SELECT IdEstado FROM @EstadosOcupados
              )
        ) AS CuposOcupados,

        v.FechaCierre,
        v.Requisitos as Requerimientos,
        v.Tipo,

        -- Siempre puede asignar porque ya filtramos arriba
        1 AS PuedeAsignar,

        (SELECT CONCAT(u.Nombre, ' ', u.Apellido1, ' ', u.Apellido2)
         FROM Usuarios u
         WHERE u.IdUsuario = @IdUsuario) AS NombreCompleto,

        CASE 
            WHEN (SELECT EstadoAcademico 
                  FROM Usuarios 
                  WHERE IdUsuario = @IdUsuario) = 1
            THEN 'Activo'
            ELSE 'Inactivo'
        END AS EstadoAcademicoDescripcion

    FROM VacantesPractica v
    INNER JOIN Empresas emp 
        ON emp.IdEmpresa = v.IdEmpresa

    WHERE
        -- Vacante activa
        v.IdEstado = 1

        -- Año actual
        AND YEAR(v.FechaCierre) = YEAR(GETDATE())

        -- Coincide con especialidad del estudiante
        AND EXISTS (
            SELECT 1
            FROM EspecialidadesVacante ev
            WHERE ev.IdVacante = v.IdVacantePractica
              AND ev.IdEspecialidad IN (
                  SELECT IdEspecialidad FROM @EspecialidadesEst
              )
        )

        -- Cupos disponibles
        AND (
            SELECT COUNT(*)
            FROM PracticaEstudiante p
            WHERE p.IdVacante = v.IdVacantePractica
              AND p.IdEstado IN (
                  SELECT IdEstado FROM @EstadosOcupados
              )
        ) < v.NumeroCupos

        -- El estudiante no tiene otra práctica activa o cerrada
        AND NOT EXISTS (
            SELECT 1
            FROM PracticaEstudiante p2
            INNER JOIN Estados e2 
                ON e2.IdEstado = p2.IdEstado
            WHERE p2.IdUsuario = @IdUsuario
              AND LOWER(LTRIM(RTRIM(e2.Descripcion))) IN (
                  'asignada',
                  'en curso',
                  'aprobada',
                  'finalizada',
                  'rezagada'
              )
        )

/****** Object:  StoredProcedure [dbo].[UltimasPracticasAsignadas]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[UltimasPracticasAsignadas]
AS
BEGIN
    SELECT TOP 5
        CONCAT(U.Nombre, ' ', U.Apellido1, ' ', U.Apellido2) AS Estudiante,
        E.Nombre AS Especialidad, 
        EM.NombreEmpresa AS NombreEmpresa, 
        P.FechaAplicacion,
        ES.Descripcion AS Estado
    FROM PracticaEstudiante P
    INNER JOIN Usuarios U ON U.IdUsuario = P.IdUsuario
    INNER JOIN UsuarioEspecialidad UE ON UE.IdUsuario = U.IdUsuario
    INNER JOIN Especialidades E ON UE.IdEspecialidad = E.IdEspecialidad
    INNER JOIN VacantesPractica V ON V.IdVacantePractica = P.IdVacante
    INNER JOIN Empresas EM ON V.IdEmpresa = EM.IdEmpresa
    INNER JOIN Estados ES ON P.IdEstado = ES.IdEstado
    WHERE P.IdEstado = 5
    ORDER BY P.FechaAplicacion DESC;
END;
GO

exec ObtenerVacantesAsignarSP 8

CREATE OR ALTER PROCEDURE [dbo].[ValidarAplicacionPracticaSP]
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM Usuarios
        WHERE IdUsuario = @IdUsuario
          AND EstadoAcademico = 0
    )
    BEGIN
        SELECT 
            0 AS PuedeAplicar,
            'El estudiante tiene estado académico rezagado, no puede aplicar.' AS Mensaje;
        RETURN;
    END;

    IF EXISTS (
        SELECT 1
        FROM PracticaEstudiante p
        INNER JOIN Estados e ON e.IdEstado = p.IdEstado
        WHERE p.IdUsuario = @IdUsuario
          AND LOWER(LTRIM(RTRIM(e.Descripcion))) IN (
              'en curso','asignada','aprobada','finalizada'
          )
    )
    BEGIN
        SELECT 
            0 AS PuedeAplicar,
            'El estudiante ya tiene una práctica asignada.' AS Mensaje;
        RETURN;
    END;

    SELECT 
        1 AS PuedeAplicar,
        'El estudiante puede aplicar a una práctica.' AS Mensaje;
END;
GO

/****** Object:  StoredProcedure [dbo].[ValidarEncargadoSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ValidarEncargadoSP]
(
    @Cedula VARCHAR(30),
    @IdUsuario INT
)
AS
BEGIN
    SELECT E.Cedula, E.Nombre, E.Apellido1, E.Apellido2, E.Ocupacion,
           E.LugarTrabajo, C.Email, E.IdEncargado, T.Telefono
    FROM Encargados E
    INNER JOIN Emails C
        ON E.IdEncargado = C.IdEncargado
    INNER JOIN Telefonos T
        ON E.IdEncargado = T.IdEncargado
    INNER JOIN EstudianteEncargado EE
        ON EE.IdEncargado = E.IdEncargado
    WHERE E.IdEstado = 1 AND E.Cedula = @Cedula AND EE.IdUsuario != @IdUsuario;
END;
GO

/****** Object:  StoredProcedure [dbo].[ValidarUsuarioEncargadoSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ValidarUsuarioEncargadoSP]
(
    @Cedula VARCHAR(30)
) 
AS
BEGIN
    SELECT IdRol, Cedula, Nombre, Apellido1, Apellido2
    FROM Usuarios
    WHERE Cedula = @Cedula;
END;
GO

/****** Object:  StoredProcedure [dbo].[ValidarUsuarioSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[ValidarUsuarioSP] 
(
    @Cedula VARCHAR(255)
)
AS
BEGIN
    SELECT U.IdUsuario, U.Cedula, U.Nombre, U.Apellido1, U.Apellido2, U.FechaNacimiento,
           U.FechaRegistro, U.FechaEgreso, U.IdRol, U.IdSeccion, U.IdEstado, E.Email AS Correo, T.Telefono, D.DireccionExacta,
           D.IdDistrito, D.IdDireccion, DD.Nombre as Distrito, C.Nombre AS Canton, C.IdCanton, P.Nombre As Provincia, P.IdProvincia,
           IM.Padecimiento, IM.Tratamiento, IM.Alergia, IM.IdInformacionMedica
    FROM Usuarios U
    LEFT JOIN Emails E ON U.IdUsuario = E.IdUsuario
    LEFT JOIN Telefonos T ON U.IdUsuario = T.IdUsuario
    LEFT JOIN Direcciones D ON U.IdDireccion = D.IdDireccion
    LEFT JOIN Distritos DD ON D.IdDistrito = DD.IdDistrito
    LEFT JOIN Cantones C ON DD.IdCanton = C.IdCanton
    LEFT JOIN Provincias P ON C.IdProvincia = P.IdProvincia
    LEFT JOIN InformacionMedica IM ON U.IdUsuario = IM.IdUsuario
    WHERE Cedula = @Cedula;
END
GO

/****** Object:  StoredProcedure [dbo].[VisualizacionPostulacionSP]    Script Date: 12/17/2025 8:16:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[VisualizacionPostulacionSP]
    @IdVacante INT,
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;

EXEC ObtenerVacantesAsignarSP 8

CREATE OR ALTER PROCEDURE ObtenerMiPracticaSP
(@IdUsuario INT)
AS
BEGIN

     DECLARE 
        @IdAprobada   INT,
        @IdRezagada   INT,
        @IdFinalizada INT,
        @IdEnCurso    INT,
        @IdAsignada  INT;

    SELECT @IdAprobada   = IdEstado FROM Estados WHERE Descripcion = 'Aprobada';
    SELECT @IdRezagada   = IdEstado FROM Estados WHERE Descripcion = 'Rezagada';
    SELECT @IdEnCurso    = IdEstado FROM Estados WHERE Descripcion = 'En Curso';
    SELECT @IdAsignada  = IdEstado FROM Estados WHERE Descripcion = 'Asignada';


    SELECT 1 IdVacante FROM PracticaEstudiante WHERE IdUsuario = @IdUsuario AND IdEstado IN (@IdAprobada, @IdRezagada, @IdEnCurso, @IdAsignada)

end;


CREATE OR ALTER PROCEDURE dbo.ListarVacantesPorUsuarioSP
(
    @IdUsuario INT
)
AS
BEGIN
    SET NOCOUNT ON;
 
    SELECT
        pe.IdPractica,
        pe.IdUsuario,
        pe.IdVacante AS IdVacante,
        pe.FechaAplicacion,
        estPractica.Descripcion AS EstadoDescripcion,
        v.Nombre AS NombreVacante,
        estVacante.Descripcion AS EstadoVacante,
        v.Requisitos,
        v.FechaMaxAplicacion,
        v.NumeroCupos,
        v.FechaCierre,
        e.NombreEmpresa as Empresa
    FROM dbo.PracticaEstudiante pe
    LEFT JOIN dbo.VacantesPractica v
        ON v.IdVacantePractica = pe.IdVacante
    LEFT JOIN dbo.Estados estPractica
        ON estPractica.IdEstado = pe.IdEstado
    LEFT JOIN dbo.Estados estVacante
        ON estVacante.IdEstado = v.IdEstado
    INNER JOIN dbo.Empresas e
    on e.IdEmpresa = v.IdEmpresa
    WHERE pe.IdUsuario = @IdUsuario
    ORDER BY pe.IdPractica DESC;
END
GO

EXEC ListarVacantesPorUsuarioSP 4