namespace SIGEP_API.Models
{
    public class VacanteListDto
    {
        public int IdVacante { get; set; }
        public string EmpresaNombre { get; set; } = "";
        public string EspecialidadNombre { get; set; } = "";
        public string Requerimientos { get; set; } = "";
        public int NumCupos { get; set; }
        public int NumPostulados { get; set; }
        public string EstadoNombre { get; set; } = "";
        public string Nombre { get; set; } = ""; 
        public int IdModalidad { get; set; }
    }
}
