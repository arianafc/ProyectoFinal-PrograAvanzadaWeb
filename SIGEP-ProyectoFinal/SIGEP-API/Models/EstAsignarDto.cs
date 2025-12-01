namespace SIGEP_API.Models
{
    public class EstAsignarDto
    {
        public int IdUsuario { get; set; }
        public string Cedula { get; set; } = "";
        public string NombreCompleto { get; set; } = "";
        public string Especialidad { get; set; } = "";
        public int EstadoAcademico { get; set; }
        public string EstadoPractica { get; set; } = "";
        public string EstadoVacante { get; set; } = "";
        public int IdPracticaVacante { get; set; }
        //public bool TieneRelacionEnVacante { get; set; }
        //public bool TienePracticaActiva { get; set; }
        //public string? TipoMensaje { get; set; }
    }
}
