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

        public string? Empresa { get; set; }

        public int IdEmpresa { get; set; }

        public string? Telefono { get; set; }

        public string? Especialidad { get; set; }

        public string? NotaFinal { get; set; }

        public string? NombreVacante { get; set; }
        public DateTime? FechaAplicacion { get; set; }
    }
}

