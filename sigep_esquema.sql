
-- Esquema SQL Server generado en español para el sistema SIGEP
CREATE DATABASE SIGEP_WEB;
GO
USE SIGEP_WEB;
GO

-- Tabla: Provincias
CREATE TABLE Provincias (
    IdProvincia INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(255) NOT NULL
);
GO

-- Tabla: Cantones
CREATE TABLE Cantones (
    IdCanton INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(255) NOT NULL,
    IdProvincia INT NOT NULL,
    CONSTRAINT FK_Canton_Provincia FOREIGN KEY (IdProvincia) REFERENCES Provincias(IdProvincia)
);
GO

-- Tabla: Distritos
CREATE TABLE Distritos (
    IdDistrito INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(255) NOT NULL,
    IdCanton INT NOT NULL,
    CONSTRAINT FK_Distrito_Canton FOREIGN KEY (IdCanton) REFERENCES Cantones(IdCanton)
);
GO

-- Tabla: Direcciones
CREATE TABLE Direcciones (
    IdDireccion INT IDENTITY(1,1) PRIMARY KEY,
    IdDistrito INT NOT NULL,
    DireccionExacta VARCHAR(MAX),
    CONSTRAINT FK_Direccion_Distrito FOREIGN KEY (IdDistrito) REFERENCES Distritos(IdDistrito)
);
GO

-- Tabla: Estados
CREATE TABLE Estados (
    IdEstado INT IDENTITY(1,1) PRIMARY KEY,
    Descripcion VARCHAR(255) NOT NULL
);
GO

-- Tabla: Roles
CREATE TABLE Roles (
    IdRol INT IDENTITY(1,1) PRIMARY KEY,
    Descripcion VARCHAR(255),
    IdEstado INT,
    CONSTRAINT FK_Rol_Estado FOREIGN KEY (IdEstado) REFERENCES Estados(IdEstado)
);
GO

-- Tabla: Secciones
CREATE TABLE Secciones (
    IdSeccion INT IDENTITY(1,1) PRIMARY KEY,
    NombreSeccion VARCHAR(30),
    IdEstado INT,
    CONSTRAINT FK_Seccion_Estado FOREIGN KEY (IdEstado) REFERENCES Estados(IdEstado)
);
GO

-- Tabla: Usuarios
CREATE TABLE Usuarios (
    IdUsuario INT IDENTITY(1,1) PRIMARY KEY,
    Cedula VARCHAR(255),
    Nombre VARCHAR(255),
    Apellido1 VARCHAR(255),
    Apellido2 VARCHAR(255),
    Contrasenna VARCHAR(255),
    FechaNacimiento DATETIME NULL,
    FechaRegistro DATETIME NULL,
    FechaEgreso DATETIME NULL,
    IdSeccion INT NULL,
    IdEstado INT NOT NULL,
    IdDireccion INT NULL,
    IdRol INT NOT NULL,
    CONSTRAINT FK_Usuario_Seccion FOREIGN KEY (IdSeccion) REFERENCES Secciones(IdSeccion),
    CONSTRAINT FK_Usuario_Estado FOREIGN KEY (IdEstado) REFERENCES Estados(IdEstado),
    CONSTRAINT FK_Usuario_Direccion FOREIGN KEY (IdDireccion) REFERENCES Direcciones(IdDireccion),
    CONSTRAINT FK_Usuario_Rol FOREIGN KEY (IdRol) REFERENCES Roles(IdRol)
);
GO

-- Tabla: Empresas
CREATE TABLE Empresas (
    IdEmpresa INT IDENTITY(1,1) PRIMARY KEY,
    NombreEmpresa VARCHAR(255),
    IdEstado INT,
    NombreContacto VARCHAR(255),
    IdDireccion INT,
    AreasAfinidad VARCHAR(255),
    CONSTRAINT FK_Empresa_Estado FOREIGN KEY (IdEstado) REFERENCES Estados(IdEstado),
    CONSTRAINT FK_Empresa_Direccion FOREIGN KEY (IdDireccion) REFERENCES Direcciones(IdDireccion)
);
GO

-- Tabla: Telefonos
CREATE TABLE Telefonos (
    IdTelefono INT IDENTITY(1,1) PRIMARY KEY,
    IdUsuario INT NULL,
    IdEmpresa INT NULL,
    IdEncargado INT NULL,
    Telefono VARCHAR(30),
    CONSTRAINT FK_Telefono_Usuario FOREIGN KEY (IdUsuario) REFERENCES Usuarios(IdUsuario),
    CONSTRAINT FK_Telefono_Empresa FOREIGN KEY (IdEmpresa) REFERENCES Empresas(IdEmpresa)
);
GO

-- Tabla: Correos
CREATE TABLE Emails (
    IdEmail INT IDENTITY(1,1) PRIMARY KEY,
    IdUsuario INT NULL,
    IdEmpresa INT NULL,
    IdEncargado INT NULL,
    Email VARCHAR(100),
    CONSTRAINT FK_Correo_Usuario FOREIGN KEY (IdUsuario) REFERENCES Usuarios(IdUsuario),
    CONSTRAINT FK_Correo_Empresa FOREIGN KEY (IdEmpresa) REFERENCES Empresas(IdEmpresa)
);
GO

-- Tabla: Documentos
CREATE TABLE Documentos (
    IdDocumento INT IDENTITY(1,1) PRIMARY KEY,
    Documento VARCHAR(255),
    Tipo VARCHAR(100),
    IdUsuario INT,
    FechaSubida DATE,
    CONSTRAINT FK_Documento_Usuario FOREIGN KEY (IdUsuario) REFERENCES Usuarios(IdUsuario)
);
GO

-- Tabla: Especialidades
CREATE TABLE Especialidades (
    IdEspecialidad INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(255),
    IdEstado INT,
    CONSTRAINT FK_Especialidad_Estado FOREIGN KEY (IdEstado) REFERENCES Estados(IdEstado)
);
GO

-- Tabla: UsuarioEspecialidad (relación muchos a muchos)
CREATE TABLE UsuarioEspecialidad (
    IdUsuarioEspecialidad INT IDENTITY(1,1) PRIMARY KEY,
    IdEspecialidad INT NOT NULL,
    IdUsuario INT NOT NULL,
    IdEstado INT,
    CONSTRAINT FK_UsuarioEspecialidad_Especialidad FOREIGN KEY (IdEspecialidad) REFERENCES Especialidades(IdEspecialidad),
    CONSTRAINT FK_UsuarioEspecialidad_Usuario FOREIGN KEY (IdUsuario) REFERENCES Usuarios(IdUsuario),
    CONSTRAINT FK_UsuarioEspecialidad_Estado FOREIGN KEY (IdEstado) REFERENCES Estados(IdEstado)
);
GO

-- Tabla: Encargados
CREATE TABLE Encargados (
    IdEncargado INT IDENTITY(1,1) PRIMARY KEY,
    Cedula VARCHAR(30),
    Nombre VARCHAR(255),
    Apellido1 VARCHAR(255),
    Apellido2 VARCHAR(255),
    FechaRegistro DATETIME,
    Ocupacion VARCHAR(255),
    LugarTrabajo VARCHAR(255),
    IdEstado INT,
    CONSTRAINT FK_Encargado_Estado FOREIGN KEY (IdEstado) REFERENCES Estados(IdEstado)
);
GO

-- Agregar llaves foráneas faltantes a Teléfonos y Correos
ALTER TABLE Telefonos
    ADD CONSTRAINT FK_Telefono_Encargado FOREIGN KEY (IdEncargado) REFERENCES Encargados(IdEncargado);
GO
ALTER TABLE Emails
    ADD CONSTRAINT FK_Correo_Encargado FOREIGN KEY (IdEncargado) REFERENCES Encargados(IdEncargado);
GO

-- Tabla: EstudianteEncargado
CREATE TABLE EstudianteEncargado (
    IdEstudianteEncargado INT IDENTITY(1,1) PRIMARY KEY,
    IdEncargado INT,
    IdUsuario INT,
    IdEstado INT,
    Parentesco VARCHAR(255),
    CONSTRAINT FK_EstudianteEncargado_Encargado FOREIGN KEY (IdEncargado) REFERENCES Encargados(IdEncargado),
    CONSTRAINT FK_EstudianteEncargado_Usuario FOREIGN KEY (IdUsuario) REFERENCES Usuarios(IdUsuario),
    CONSTRAINT FK_EstudianteEncargado_Estado FOREIGN KEY (IdEstado) REFERENCES Estados(IdEstado)
);
GO

-- Tabla: InformacionMedica
CREATE TABLE InformacionMedica (
    IdInformacionMedica INT IDENTITY(1,1) PRIMARY KEY,
    IdUsuario INT,
    Padecimiento VARCHAR(255),
    Tratamiento VARCHAR(255),
    Alergia VARCHAR(255),
    CONSTRAINT FK_InformacionMedica_Usuario FOREIGN KEY (IdUsuario) REFERENCES Usuarios(IdUsuario)
);
GO

-- Tabla: Modalidades
CREATE TABLE Modalidades (
    IdModalidad INT IDENTITY(1,1) PRIMARY KEY,
    Descripcion VARCHAR(100)
);
GO

-- Tabla: VacantesPractica
CREATE TABLE VacantesPractica (
    IdVacantePractica INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(255),
    IdEstado INT,
    IdEmpresa INT,
    Requisitos VARCHAR(MAX),
    FechaMaxAplicacion DATE,
    NumeroCupos INT,
    FechaCierre DATE,
    IdModalidad INT,
    Descripcion VARCHAR(255),
    Tipo VARCHAR(255),
    CONSTRAINT FK_VacantePractica_Estado FOREIGN KEY (IdEstado) REFERENCES Estados(IdEstado),
    CONSTRAINT FK_VacantePractica_Empresa FOREIGN KEY (IdEmpresa) REFERENCES Empresas(IdEmpresa),
    CONSTRAINT FK_VacantePractica_Modalidad FOREIGN KEY (IdModalidad) REFERENCES Modalidades(IdModalidad)
);
GO

-- Tabla: EspecialidadesVacante
CREATE TABLE EspecialidadesVacante (
    IdEspecialidadVacante INT IDENTITY(1,1) PRIMARY KEY,
    IdVacante INT,
    IdEspecialidad INT,
    CONSTRAINT FK_EspecialidadVacante_Vacante FOREIGN KEY (IdVacante) REFERENCES VacantesPractica(IdVacantePractica),
    CONSTRAINT FK_EspecialidadVacante_Especialidad FOREIGN KEY (IdEspecialidad) REFERENCES Especialidades(IdEspecialidad)
);
GO

-- Tabla: PracticasEstudiante
CREATE TABLE PracticaEstudiante (
    IdPractica INT IDENTITY(1,1) PRIMARY KEY,
    IdVacante INT,
    IdEstado INT,
    IdUsuario INT,
    FechaAplicacion DATE,
    CONSTRAINT FK_PracticaEstudiante_Vacante FOREIGN KEY (IdVacante) REFERENCES VacantesPractica(IdVacantePractica),
    CONSTRAINT FK_PracticaEstudiante_Estado FOREIGN KEY (IdEstado) REFERENCES Estados(IdEstado),
    CONSTRAINT FK_PracticaEstudiante_Usuario FOREIGN KEY (IdUsuario) REFERENCES Usuarios(IdUsuario)
);
GO

-- Tabla: ComentariosPractica
CREATE TABLE ComentariosPractica (
    IdComentario INT IDENTITY(1,1) PRIMARY KEY,
    Comentario VARCHAR(100),
    Fecha DATE,
    IdUsuario INT,
    IdPractica INT,
    Nota DECIMAL(10,2),
    Tipo VARCHAR(255),
    CONSTRAINT FK_ComentarioPractica_Usuario FOREIGN KEY (IdUsuario) REFERENCES Usuarios(IdUsuario),
    CONSTRAINT FK_ComentarioPractica_Practica FOREIGN KEY (IdPractica) REFERENCES PracticaEstudiante(IdPractica)
);
GO

-- Tabla: Comunicado
CREATE TABLE Comunicados (
    IdComunicado INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(255),
    IdEstado INT,
    Informacion VARCHAR(255),
    Fecha DATETIME,
    Poblacion VARCHAR(255),
    FechaLimite DATETIME,
    IdUsuario INT,
    CONSTRAINT FK_Comunicado_Estado FOREIGN KEY (IdEstado) REFERENCES Estados(IdEstado),
    CONSTRAINT FK_Comunicado_Usuario FOREIGN KEY (IdUsuario) REFERENCES Usuarios(IdUsuario)
);
GO

-- Tabla: AuditoriaGlobal
CREATE TABLE AuditoriaGlobal (
    IdAuditoria INT IDENTITY(1,1) PRIMARY KEY,
    IdUsuario INT,
    TablaAfectada VARCHAR(100),
    IdRegistro INT,
    Accion VARCHAR(100),
    CampoAfectado VARCHAR(100),
    DatoAntes VARCHAR(255),
    DatoDespues VARCHAR(255),
    CONSTRAINT FK_AuditoriaGlobal_Usuario FOREIGN KEY (IdUsuario) REFERENCES Usuarios(IdUsuario)
);
GO

-- Fin del esquema
