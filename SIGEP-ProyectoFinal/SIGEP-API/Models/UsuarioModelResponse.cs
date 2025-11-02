namespace SIGEP_API.Models
{
    public class UsuarioModelResponse
    {
        public int IdUsuario { get; set; }  
        public string? Cedula { get; set; }
        public string? Contrasenna { get; set; }

        public string? Correo { get; set; }

        public string? Nombre { get; set; }

        public int IdRol { get; set; }

        public int IdEstado { get; set; }

        public string? Apellido1 { get; set; }

        public string? Apellido2 { get; set; }

        public string? Seccion { get; set; }

        public int IdSeccion { get; set; }

        public int IdEspecialidad { get; set; }

        public string? Telefono { get; set; }

        public DateTime? FechaNacimiento { get; set; }

        public string? Sexo { get; set; }

        public string? Nacionalidad { get; set; }

        public string? Provincia { get; set; }

        public string? Distrito { get; set; }

        public string? Canton { get; set; }

        public string? DireccionExacta { get; set; }

        public string? Padecimiento { get; set; }

        public string? Medicamento { get; set; }

        public string? Alergia { get; set; }

    }
}
