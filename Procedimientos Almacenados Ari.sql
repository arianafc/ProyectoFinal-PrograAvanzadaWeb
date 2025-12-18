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
    AND Contrasenna = @CONTRASENNA AND U.IdEstado = 1;
END;
GO


USE [SIGEP_WEB]
GO

/****** Object:  StoredProcedure [dbo].[RegistroSP]    Script Date: 10/26/2025 11:05:22 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE  OR ALTER PROCEDURE [dbo].[RegistroSP] 
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
            @Contrasenna, 
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
    SET Contrasenna = @Contrasenna
    WHERE IdUsuario = @IdUsuario;
END;
GO



CREATE OR ALTER PROCEDURE ObtenerEncargadosSP (
@IdUsuario INT)
AS
BEGIN
    SELECT E.Cedula, E.Nombre, E.Apellido1, E.Apellido2, E.FechaRegistro, E.Ocupacion, E.LugarTrabajo, E.IdEncargado, EE.IdEstado,
    EE.Parentesco, C.Email as Correo, T.Telefono
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

CREATE OR ALTER PROCEDURE AccionesEncargadoSP
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

CREATE OR ALTER PROCEDURE ValidarEncargadoSP
(@Cedula VARCHAR(30), @IdUsuario INT)
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

--VALIDAMOS SI EL ENCARGADO ES UN ESTUDIANTE
CREATE OR ALTER PROCEDURE ValidarUsuarioEncargadoSP
(@Cedula VARCHAR(30)) 
AS
BEGIN
    SELECT IdRol, Cedula, Nombre, Apellido1, Apellido2
    FROM Usuarios
    WHERE Cedula = @Cedula;
END;

CREATE OR ALTER PROCEDURE ObtenerEncargadoSP(@IdEncargado INT, @IdUsuario INT)
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


CREATE OR ALTER PROCEDURE SubirDocumentosPerfilSP
(@IdUsuario INT, @Documento VARCHAR(255))
AS
BEGIN

INSERT INTO Documentos (Documento, Tipo, IdUsuario, FechaSubida) VALUES
(@Documento, 'Perfil', @IdUsuario, GETDATE());

END

CREATE OR ALTER PROCEDURE ObtenerDocumentosPerfilSP
(@IdUsuario INT)
AS
BEGIN

    SELECT [IdDocumento]
      ,[Documento]
      ,[Tipo]
      ,[IdUsuario]
      ,[FechaSubida]
  FROM [dbo].[Documentos] WHERE IdUsuario = @IdUsuario;

END

CREATE OR ALTER PROCEDURE EliminarDocumentoSP
(@IdDocumento INT)
AS
BEGIN

    DELETE FROM Documentos WHERE IdDocumento = @IdDocumento;

END


USE [SIGEP_WEB]
GO

/****** Object:  StoredProcedure [dbo].[RegistrarError]    Script Date: 12/7/2025 7:36:34 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[RegistrarError]
	@IdUsuario INT,
    @MensajeError VARCHAR(MAX),
    @OrigenError VARCHAR(50)
AS
BEGIN

    INSERT INTO dbo.Errores (IdUsuario,Mensaje,Origen,FechaHora)
    VALUES (@IdUsuario, @MensajeError, @OrigenError, GETDATE())

END
GO



/****** Object:  Table [dbo].[tbError]    Script Date: 12/7/2025 7:24:39 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Errores](
	[IdError] [int] IDENTITY(1,1) NOT NULL,
	[IdUsuario] [int] NOT NULL,
	[Mensaje] [varchar](max) NOT NULL,
	[Origen] [varchar](50) NOT NULL,
	[FechaHora] [datetime] NOT NULL,
 CONSTRAINT [PK_tbError] PRIMARY KEY CLUSTERED 
(
	[IdError] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE Documentos
ADD IdComunicado INT

ALTER TABLE Documentos
ADD FOREIGN KEY (IdComunicado) REFERENCES Comunicados(IdComunicado)


CREATE OR ALTER PROCEDURE ObtenerComunicadosSP
(
    @Poblacion VARCHAR(255)
)
AS
BEGIN
    SET NOCOUNT ON;

    -- CASO ADMINISTRATIVOS: VE TODO
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
        -- RESTO DE POBLACIONES
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


CREATE OR ALTER PROCEDURE ObtenerDocumentosComunicadoSP
(@IdComunicado INT)
AS
BEGIN
    SELECT IdDocumento, Documento, Tipo, IdUsuario, FechaSubida, IdComunicado
    FROM Documentos
    WHERE IdComunicado = @IdComunicado;


END;

GO

alter table comunicados
alter Column Informacion VARCHAR(MAX)

GO

CREATE OR ALTER PROCEDURE AgregarComunicadoSP
(@Nombre VARCHAR(255), @Informacion VARCHAR(MAX), 
 @Poblacion VARCHAR(255), @FechaLimite DATETIME, @IdUsuario INT)
AS
BEGIN
    

    INSERT INTO Comunicados (Nombre,IdEstado, Informacion, Fecha, Poblacion, FechaLimite, IdUsuario) VALUES
    (@Nombre, 1, @Informacion, GETDATE(), @Poblacion, @FechaLimite, @IdUsuario)
      
      SELECT SCOPE_IDENTITY();



END;

GO

CREATE OR ALTER PROCEDURE GuardarDocumentosComunicadoSP (  @IdComunicado INT,
    @NombreArchivo VARCHAR(255),
    @Tipo VARCHAR(100))
AS
BEGIN

    INSERT INTO Documentos (Documento, Tipo, IdComunicado, FechaSubida)
    VALUES (@NombreArchivo, @Tipo, @IdComunicado, GETDATE());


END;

GO;

CREATE OR ALTER PROCEDURE ObtenerDetallesComunicadoSP (@IdComunicado INT)
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
    WHERE 
       C.IdComunicado = @IdComunicado
    
END;


GO

CREATE OR ALTER PROCEDURE EditarComunicadoSP
(@IdComunicado INT,
@Nombre VARCHAR(255), 
@Informacion VARCHAR(MAX),
@FechaLimite DATETIME,
@Poblacion VARCHAR(255))
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

CREATE OR ALTER PROCEDURE CambiarEstadoComunicadoSP(@IdComunicado INT, @IdEstado INT)
AS
BEGIN

    UPDATE Comunicados SET IdEstado = @IdEstado WHERE IdComunicado = @IdComunicado;

END;


CREATE OR ALTER PROCEDURE ObtenerEmailsSP (@Destinatario VARCHAR(255))
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


CREATE OR ALTER PROCEDURE IndicadoresDashboard
AS
BEGIN
    SET NOCOUNT ON;

    SELECT

              (SELECT COUNT(*)
         FROM Usuarios
         WHERE IdRol = 1
           AND IdEstado = 1) AS EstudiantesActivos,

        -- Estudiantes con práctica asignada
        (SELECT COUNT(DISTINCT PE.IdUsuario)
         FROM PracticaEstudiante PE
         INNER JOIN Usuarios U ON U.IdUsuario = PE.IdUsuario
         WHERE U.IdRol = 1
           AND U.IdEstado = 1
           AND PE.IdEstado = 5) AS EstudiantesConPractica,

        -- Estudiantes sin práctica asignada
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

        -- Prácticas asignadas
        (SELECT COUNT(*)
         FROM PracticaEstudiante
         WHERE IdEstado = 5) AS PracticasAsignadas,

        -- Prácticas finalizadas
        (SELECT COUNT(*)
         FROM PracticaEstudiante
         WHERE IdEstado = 8) AS PracticasFinalizadas,

        -- Empresas registradas
        (SELECT COUNT(*)
         FROM Empresas
         WHERE IdEstado = 1) AS EmpresasRegistradas;

END;


CREATE OR ALTER PROCEDURE UltimasPracticasAsignadasSP
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

INSERT INTO Modalidades VALUES ('Hibrido')

USE [SIGEP_WEB]
GO

/****** Object:  StoredProcedure [dbo].[ObtenerPostulacionesSP]    Script Date: 12/16/2025 9:34:11 PM ******/
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
    LEFT JOIN NotasEstudiantesTB n ON n.IdUsuario = u.IdUsuario
    WHERE YEAR(p.FechaAplicacion) = YEAR(GETDATE())
    ORDER BY p.IdPractica DESC;
END
GO



CREATE  OR ALTER  PROCEDURE [dbo].[ObtenerHistoricoSP]
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


CREATE OR ALTER PROCEDURE IniciarPracticasSP
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

        -------------------------------------------------
        -- 1. Asignada + estudiante activo → En Curso
        -------------------------------------------------
        UPDATE p
        SET p.IdEstado = @IdEnCurso
        FROM PracticaEstudiante p
        INNER JOIN Usuarios u ON u.IdUsuario = p.IdUsuario
        WHERE p.IdEstado = @IdAsignada
          AND u.EstadoAcademico = 1;

        -------------------------------------------------
        -- 2. Todo lo demás → Retirada
        --    (excepto En Curso, Finalizada, Aprobada, Rezagada)
        -------------------------------------------------
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


CREATE OR ALTER PROCEDURE FinalizarPracticasSP
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
        INNER JOIN NotasEstudiantesTB n 
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

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO


CREATE OR ALTER PROCEDURE [dbo].[ObtenerVacantesAsignarSP]
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EspecialidadesEst TABLE (IdEspecialidad INT);
    INSERT INTO @EspecialidadesEst (IdEspecialidad)
    SELECT DISTINCT IdEspecialidad
    FROM UsuarioEspecialidad
    WHERE IdUsuario = @IdUsuario
      AND IdEstado = 1;

    DECLARE @EstadosOcupados TABLE (IdEstado INT);
    INSERT INTO @EstadosOcupados (IdEstado)
    SELECT IdEstado
    FROM Estados
    WHERE LOWER(LTRIM(RTRIM(Descripcion))) IN (
        'asignada','en curso','aprobada','finalizada','rezagado'
    );

    SELECT
        v.IdVacantePractica,
        LTRIM(RTRIM(v.Nombre)) AS NombreVacante,
        emp.NombreEmpresa,

        ISNULL((
            SELECT TOP 1 esp.Nombre
            FROM EspecialidadesVacante ev
            INNER JOIN Especialidades esp ON esp.IdEspecialidad = ev.IdEspecialidad
            WHERE ev.IdVacante = v.IdVacantePractica
              AND ev.IdEspecialidad IN (SELECT IdEspecialidad FROM @EspecialidadesEst)
        ), '—') AS Especialidad,

        v.NumeroCupos,

        (
            SELECT COUNT(*)
            FROM PracticaEstudiante p
            WHERE p.IdVacante = v.IdVacantePractica
              AND p.IdEstado IN (SELECT IdEstado FROM @EstadosOcupados)
        ) AS CuposOcupados,

        v.FechaCierre,
        v.Requisitos,
        v.Tipo,

        CASE 
            WHEN v.Tipo IS NOT NULL 
                 AND LOWER(LTRIM(RTRIM(v.Tipo))) = 'autogestionada'
                 AND EXISTS (
                     SELECT 1 
                     FROM PracticaEstudiante p
                     WHERE p.IdUsuario = @IdUsuario
                       AND p.IdVacante = v.IdVacantePractica
                       AND p.IdEstado IN (3,5,6,8,9,11)
                 )
            THEN 'Autogestionada'
            ELSE NULL
        END AS TipoMensaje,

        ISNULL((
            SELECT TOP 1 LTRIM(RTRIM(e2.Descripcion))
            FROM PracticaEstudiante p2
            INNER JOIN Estados e2 ON e2.IdEstado = p2.IdEstado
            WHERE p2.IdUsuario = @IdUsuario
              AND p2.IdVacante = v.IdVacantePractica
            ORDER BY p2.IdPractica DESC
        ), 'Sin proceso activo') AS EstadoPractica,

        ISNULL((
            SELECT TOP 1 p3.IdPractica
            FROM PracticaEstudiante p3
            WHERE p3.IdUsuario = @IdUsuario
              AND p3.IdVacante = v.IdVacantePractica
            ORDER BY p3.IdPractica DESC
        ), 0) AS IdPracticaVacante,

        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM PracticaEstudiante p4
                INNER JOIN Estados e4 ON e4.IdEstado = p4.IdEstado
                WHERE p4.IdUsuario = @IdUsuario
                  AND p4.IdVacante <> v.IdVacantePractica
                  AND LOWER(LTRIM(RTRIM(e4.Descripcion))) IN (
                      'en curso','asignada','aprobada','finalizada','rezagado'
                  )
            ) THEN 0
            ELSE 1
        END AS PuedeAsignar,

        (SELECT CONCAT(u.Nombre, ' ', u.Apellido1, ' ', u.Apellido2)
         FROM Usuarios u 
         WHERE u.IdUsuario = @IdUsuario) AS NombreCompleto,

        CASE 
            WHEN (SELECT EstadoAcademico FROM Usuarios WHERE IdUsuario = @IdUsuario) = 1
            THEN 'Activo' 
            ELSE 'Inactivo' 
        END AS EstadoAcademicoDescripcion

    FROM VacantesPractica v
    INNER JOIN Empresas emp ON emp.IdEmpresa = v.IdEmpresa

    WHERE 
    (
        v.IdEstado IN (1, 5)
        AND EXISTS (
            SELECT 1
            FROM EspecialidadesVacante ev
            WHERE ev.IdVacante = v.IdVacantePractica
              AND ev.IdEspecialidad IN (SELECT IdEspecialidad FROM @EspecialidadesEst)
        )
    )
    OR 
    (
        EXISTS (
            SELECT 1
            FROM PracticaEstudiante p
            WHERE p.IdUsuario = @IdUsuario
              AND p.IdVacante = v.IdVacantePractica
              AND p.IdEstado IN (3,5,6,8,9,11)
        )
    )

    ORDER BY v.Nombre;
END;
GO

exec ObtenerVacantesAsignarSP 8

CREATE OR ALTER PROCEDURE [dbo].[ValidarAplicacionPracticaSP]
    @IdUsuario INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1️⃣ Validar estado académico
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

    -- 2️⃣ Validar si ya tiene una práctica asignada
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

    -- 3️⃣ Si todo está bien
    SELECT 
        1 AS PuedeAplicar,
        'El estudiante puede aplicar a una práctica.' AS Mensaje;
END;
GO

EXEC ObtenerVacantesAsignarSP 8