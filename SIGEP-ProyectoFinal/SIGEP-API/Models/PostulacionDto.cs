namespace SIGEP_API.Models
{
    public class PostulacionDto
    {
        public int IdPractica { get; set; }
        public int IdVacante { get; set; }
        public int IdUsuario { get; set; }
        public string Cedula { get; set; } = "";
        public string NombreCompleto { get; set; } = "";
        public string EstadoDescripcion { get; set; } = "";
    }
}
