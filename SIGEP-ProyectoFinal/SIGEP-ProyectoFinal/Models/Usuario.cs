namespace SIGEP_ProyectoFinal.Models
{
    public class Usuario
    {
        public int IdUsuario { get; set; }
        public string? Cedula { get; set; }
        public string? Contrasenna { get; set; }

        public string? CorreoPersonal { get; set; }
        public string? CorreoMEP { get; set; }

        public string? Nombre { get; set; }

        public int IdRol { get; set; }

        public int IdEstado { get; set; }   

        public string? Apellido1 { get; set; }

        public string? Apellido2 { get; set; }

        public string? Seccion { get; set; }

        public int IdSeccion { get; set; }

        public int IdEspecialidad { get; set; }

        public string? Telefono { get; set; }

        public List<Secciones> ListaSecciones { get; set; } = new List<Secciones>();

        public List<Especialidades> ListaEspecialidades { get; set; } = new List<Especialidades>();

        public DateTime? FechaNacimiento { get; set; }

        public string? ConfirmarContrasenna { get; set; }

    }
}
