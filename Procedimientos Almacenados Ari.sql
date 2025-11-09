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
SELECT U.IdUsuario, U.Cedula, U.Nombre, U.Apellido1, U.Apellido2, U.FechaNacimiento,
    U.FechaRegistro, U.FechaEgreso, U.IdRol, U.IdSeccion, U.IdEstado, E.Email AS Correo, T.Telefono, D.DireccionExacta,
    D.IdDistrito, D.IdDireccion, DD.Nombre as Distrito, C.Nombre AS Canton, C.IdCanton, P.Nombre As Provincia, P.IdProvincia,
    IM.Padecimiento, IM.Tratamiento, IM.Alergia, IM.IdInformacionMedica
    FROM Usuarios U
    LEFT JOIN Emails E
    ON U.IdUsuario = E.IdUsuario
    LEFT JOIN Telefonos T
    ON U.IdUsuario = T.IdUsuario
    LEFT JOIN Direcciones D
    ON U.IdDireccion = D.IdDireccion
    LEFT JOIN Distritos DD
    ON D.IdDistrito = DD.IdDistrito
    LEFT JOIN Cantones C
    ON DD.IdCanton = C.IdCanton
    LEFT JOIN Provincias P
    ON C.IdProvincia = P.IdProvincia
    LEFT JOIN InformacionMedica IM
    ON U.IdUsuario = IM.IdUsuario
  WHERE Cedula = @Cedula;
END


 CREATE OR ALTER PROCEDURE ObtenerPerfilSP 
  (@IdUsuario int)
  AS
  BEGIN
SELECT U.IdUsuario, U.Cedula, U.Nombre, U.Apellido1, U.Apellido2, U.FechaNacimiento,
    U.FechaRegistro, U.FechaEgreso, U.IdRol, U.IdSeccion, U.IdEstado, E.Email AS Correo, T.Telefono, D.DireccionExacta,
    D.IdDistrito, D.IdDireccion, DD.Nombre as Distrito, C.Nombre AS Canton, C.IdCanton, P.Nombre As Provincia, P.IdProvincia,
    IM.Padecimiento, IM.Tratamiento, IM.Alergia, IM.IdInformacionMedica
    FROM Usuarios U
    LEFT JOIN Emails E
    ON U.IdUsuario = E.IdUsuario
    LEFT JOIN Telefonos T
    ON U.IdUsuario = T.IdUsuario
    LEFT JOIN Direcciones D
    ON U.IdDireccion = D.IdDireccion
    LEFT JOIN Distritos DD
    ON D.IdDistrito = DD.IdDistrito
    LEFT JOIN Cantones C
    ON DD.IdCanton = C.IdCanton
    LEFT JOIN Provincias P
    ON C.IdProvincia = P.IdProvincia
    LEFT JOIN InformacionMedica IM
    ON U.IdUsuario = IM.IdUsuario
  WHERE u.IdUsuario = @IdUsuario;
END


drop procedure ObtenerPefilSP


/****** Object:  StoredProcedure [dbo].[ActualizarContrasenna]    Script Date: 11/1/2025 12:53:17 AM ******/
SET ANSI_NULLS ON
GO

CREATE OR ALTER   PROCEDURE [dbo].[ActualizarContrasennaSP]
    @IdUsuario VARCHAR(100),
    @Contrasenna VARCHAR(100)
AS
BEGIN
    -- Verifica si el usuario exist
    -- Actualiza la contraseña encriptada
    UPDATE Usuarios
    SET Contrasenna = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', @Contrasenna), 2)
    WHERE IdUsuario = @IdUsuario;
END;
GO



CREATE OR ALTER PROCEDURE ObtenerEncargadosSP (
@IdUsuario INT)
AS
BEGIN
    SELECT E.Cedula, E.Nombre, E.Apellido1, E.Apellido2, E.FechaRegistro, E.Ocupacion, E.LugarTrabajo, E.IdEncargado, EE.IdEstado,
    EE.Parentesco, C.Email as Correo
    FROM Encargados E
    INNER JOIN EstudianteEncargado EE
    ON E.IdEncargado = EE.IdEncargado
    LEFT JOIN Emails C
    ON C.IdEncargado = E.IdEncargado
    WHERE EE.IdUsuario = @IdUsuario
    AND EE.IdEstado = 1;
END;


