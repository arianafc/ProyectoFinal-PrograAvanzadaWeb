namespace SIGEP_API.Models
{
    public class VacanteDetalleDto
    {
        public int IdVacante { get; set; }
        public string Nombre { get; set; } = "";
        public int IdEmpresa { get; set; }
        public string EmpresaNombre { get; set; } = "";
        public int IdEspecialidad { get; set; }
        public int? IdModalidad { get; set; }
        public string Descripcion { get; set; } = "";
        public string Requisitos { get; set; } = "";
        public int NumCupos { get; set; }
        public DateTime? FechaMaxAplicacion { get; set; }
        public DateTime? FechaCierre { get; set; }
        public string Tipo { get; set; }
        public string EstadoNombre { get; set; } = "";
        public string Especialidades { get; set; } = "";
        public string Ubicacion { get; set; } = "";
    }
}
