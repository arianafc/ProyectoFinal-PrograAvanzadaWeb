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
SELECT U.IdUsuario, U.Cedula, U.Nombre, U.Apellido1, U.Apellido2, U.FechaNacimiento, U.Nacionalidad, U.Sexo,
    U.FechaRegistro, U.FechaEgreso, U.IdRol, U.IdSeccion, U.IdEstado, E.Email AS Correo, T.Telefono, D.DireccionExacta,
    D.IdDistrito, D.IdDireccion, DD.Nombre as Distrito, C.Nombre AS Canton, C.IdCanton, P.Nombre As Provincia, P.IdProvincia,
    IM.Padecimiento, IM.Tratamiento, IM.Alergia, IM.IdInformacionMedica, ES.IdEspecialidad, ES.Nombre AS Especialidad
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
    LEFT JOIN UsuarioEspecialidad UE
    ON UE.IdUsuario = U.IdUsuario
    LEFT JOIN Especialidades ES
    ON ES.IdEspecialidad = UE.IdEspecialidad
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




USE [SIGEP_WEB]
GO

/****** Object:  StoredProcedure [dbo].[ObtenerPerfilSP]    Script Date: 11/14/2025 6:06:36 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER PROCEDURE ObtenerPerfilSP
  (@IdUsuario int)
  AS
  BEGIN
SELECT U.IdUsuario, U.Cedula, U.Nombre, U.Apellido1, U.Apellido2, U.FechaNacimiento,
    U.FechaRegistro, U.FechaEgreso, U.IdRol, U.IdSeccion, U.IdEstado, E.Email AS Correo, T.Telefono, D.DireccionExacta,
    D.IdDistrito, D.IdDireccion, DD.Nombre as Distrito, C.Nombre AS Canton, C.IdCanton, P.Nombre As Provincia, P.IdProvincia,
    IM.Padecimiento, IM.Tratamiento, IM.Alergia, IM.IdInformacionMedica, UE.IdEspecialidad, U.Sexo, U.Nacionalidad
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
    LEFT JOIN UsuarioEspecialidad UE
    ON U.IdUsuario = UE.IdUsuario
  WHERE u.IdUsuario = @IdUsuario;
END

GO

CREATE OR ALTER PROCEDURE ActualizarInformacionPersonalSP 
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
    DECLARE @IdDireccion     INT;  -- para la dirección del usuario

    ------------------------------------------------------
    -- 1. Actualizar datos básicos del usuario
    ------------------------------------------------------
    UPDATE Usuarios
    SET Nombre         = @Nombre,
        Apellido1      = @Apellido1,
        Apellido2      = @Apellido2,
        Cedula         = @Cedula,
        FechaNacimiento = @FechaNacimiento,
        Sexo = @Sexo,
        Nacionalidad = @Nacionalidad
    WHERE IdUsuario = @IdUsuario;

    ------------------------------------------------------
    -- 2. Correo: actualizar si existe, si no insertar
    ------------------------------------------------------
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

    ------------------------------------------------------
    -- 3. Teléfono: actualizar si existe, si no insertar
    ------------------------------------------------------
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

    ------------------------------------------------------
    -- 4. Provincia: obtener o crear y luego obtener IdProvincia
    ------------------------------------------------------
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

    ------------------------------------------------------
    -- 5. Cantón: obtener o crear y luego obtener IdCanton
    ------------------------------------------------------
    SELECT @ExisteCanton = COUNT(*)
    FROM Cantones
    WHERE Nombre = @Canton
      AND IdProvincia = @IdProvincia;  -- opcional pero recomendable

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

    ------------------------------------------------------
    -- 6. Distrito: obtener o crear y luego obtener IdDistrito
    ------------------------------------------------------
    SELECT @ExisteDistrito = COUNT(*)
    FROM Distritos
    WHERE Nombre = @Distrito
      AND IdCanton = @IdCanton;  -- opcional pero recomendable

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

    ------------------------------------------------------
    -- 7. Dirección: actualizar si existe, si no insertar y asociar al usuario
    ------------------------------------------------------
    -- Asumo que Usuarios tiene columna IdDireccion
    SELECT @IdDireccion = IdDireccion
    FROM Usuarios
    WHERE IdUsuario = @IdUsuario;

    IF @IdDireccion IS NOT NULL
    BEGIN
        -- Actualizar dirección existente
        UPDATE Direcciones
        SET DireccionExacta = @DireccionExacta,
            IdDistrito      = @IdDistrito
        WHERE IdDireccion = @IdDireccion;
    END
    ELSE
    BEGIN
        -- Crear nueva dirección y asociarla al usuario
        INSERT INTO Direcciones (DireccionExacta, IdDistrito)
        VALUES (@DireccionExacta, @IdDistrito);

        SELECT @IdDireccion = SCOPE_IDENTITY();

        UPDATE Usuarios
        SET IdDireccion = @IdDireccion
        WHERE IdUsuario = @IdUsuario;
    END;
END;
GO


CREATE OR ALTER PROCEDURE ActualizarInfoAcademicaSP
(@IdUsuario INT,
@IdSeccion INT,
@IdEspecialidad INT)
AS
BEGIN
    UPDATE Usuarios SET IdSeccion = @IdSeccion WHERE IdUsuario = @IdUsuario;

    UPDATE UsuarioEspecialidad SET IdEspecialidad = @IdEspecialidad WHERE IdUsuario = @IdUsuario;

END;


CREATE OR ALTER PROCEDURE ActualizarInfoMedicaSP
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













END
