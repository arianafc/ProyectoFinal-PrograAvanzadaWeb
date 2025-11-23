namespace SIGEP_API.Models
{
    public class EstudianteListItemModel
    {
        public int IdUsuario { get; set; }
        public string Cedula { get; set; } = "";
        public string NombreCompleto { get; set; } = "";
        public string Telefono { get; set; } = "";
        public string EspecialidadNombre { get; set; } = "";
        public bool? EstadoAcademico { get; set; }
        public string EstadoPractica { get; set; } = "";
        public int IdEstado { get; set; }
    }
}
