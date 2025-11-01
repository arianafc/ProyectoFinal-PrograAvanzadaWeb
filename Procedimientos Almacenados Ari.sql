USE [SIGEP_WEB]
GO

/****** Object:  StoredProcedure [dbo].[LoginSP]    Script Date: 10/26/2025 10:55:17 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

create or alter PROCEDURE [dbo].[LoginSP]
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
    on U.IdSeccion = S.IdSeccion
    INNER JOIN dbo.UsuarioEspecialidad UE
    ON UE.IdUsuario = U.IdUsuario
    INNER JOIN dbo.Especialidades E
    ON UE.IdEspecialidad = E.IdEspecialidad
    WHERE U.Cedula = @CEDULA
    AND Contrasenna = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', @CONTRASENNA), 2);
END;
GO


USE [SIGEP_WEB]
GO

/****** Object:  StoredProcedure [dbo].[RegistroSP]    Script Date: 10/26/2025 11:05:22 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE [dbo].[RegistroSP] 
    @Nombre VARCHAR(20), 
    @Apellido1 VARCHAR(50), 
    @Apellido2 VARCHAR(50), 
    @Correo VARCHAR(255), 
    @IdEspecialidad INT,
    @FechaNacimiento DATETIME,
    @IdSeccion INT,
    @Contrasenna VARCHAR(255), 
    @Cedula VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdUsuario INT;

    -- Validaciones
    IF @IdSeccion IS NULL
    BEGIN
        RAISERROR('La sección especificada no existe.', 16, 1);
        RETURN;
    END

    IF @IdEspecialidad IS NULL
    BEGIN
        RAISERROR('La especialidad especificada no existe.', 16, 1);
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM Usuarios WHERE Cedula = @Cedula)
    BEGIN
        RAISERROR('Imposible completar el registro. Ya existe una cuenta asociada a esa cédula.', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRAN;

        -- Insertar usuario
        INSERT INTO dbo.Usuarios (Nombre, Apellido1, Apellido2, Contrasenna, FechaNacimiento, Cedula, IdEstado, IdRol, IdSeccion, FechaRegistro)
        VALUES (
            @Nombre, 
            @Apellido1, 
            @Apellido2, 
            CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', @Contrasenna), 2), 
            @FechaNacimiento,
            @Cedula, 
            1,
            1, -- Estudiante
            @IdSeccion,
            GETDATE()
        );

        SET @IdUsuario = SCOPE_IDENTITY();

        -- Insertar correo
        INSERT INTO dbo.Emails (IdUsuario, Email) 
        VALUES (@IdUsuario, @Correo);

        -- Relación usuario-especialidad
        INSERT INTO dbo.UsuarioEspecialidad (IdEspecialidad, IdUsuario, IdEstado) 
        VALUES (@IdEspecialidad, @IdUsuario, 1);

        COMMIT;

        -- Devolver el ID
        SELECT @IdUsuario AS IdUsuario;

    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO


CREATE OR ALTER PROCEDURE ObtenerSeccionesSP 
AS
BEGIN
    SELECT IdSeccion, Seccion
    FROM Secciones WHERE IdEstado = 1;
END;

CREATE OR ALTER PROCEDURE ObtenerEspecialidadesSP 
AS
BEGIN
    SELECT IdEspecialidad, Nombre
    FROM Especialidades WHERE IdEstado = 1;
END;


 CREATE OR ALTER PROCEDURE ValidarUsuarioSP 
  (@Cedula VARCHAR(255))
  AS
  BEGIN


SELECT [IdUsuario]
      ,[Cedula]
      ,[Nombre]
      ,[Apellido1]
      ,[Apellido2]
      ,[Contrasenna]
      ,[FechaNacimiento]
      ,[FechaRegistro]
      ,[FechaEgreso]
      ,[IdSeccion]
      ,[IdEstado]
      ,[IdDireccion]
      ,[IdRol]
  FROM [dbo].[Usuarios]
  WHERE Cedula = @Cedula;

END

