namespace SIGEP_API.Models
{
    public class PerfilEstudianteResponseModel
    {
        public int IdUsuario { get; set; }
        public string Cedula { get; set; } = string.Empty;
        public string NombreCompleto { get; set; } = string.Empty;
        public string Nombre { get; set; } = string.Empty;
        public string Apellido1 { get; set; } = string.Empty;
        public string Apellido2 { get; set; } = string.Empty;
        public string Correo { get; set; } = string.Empty;
        public string Telefono { get; set; } = string.Empty;
        public string Direccion { get; set; } = string.Empty;
        public string Sexo { get; set; } = string.Empty;
        public string Especialidad { get; set; } = string.Empty;
        public int Edad { get; set; }
        public string Seccion { get; set; } = string.Empty;
        public string NombreEmpresa { get; set; } = string.Empty;
        public string TelefonoEmpresa { get; set; } = string.Empty;
        public int? IdVacante { get; set; }
        public int IdEstudiante { get; set; }
        public int IdPractica { get; set; }
    }
}
