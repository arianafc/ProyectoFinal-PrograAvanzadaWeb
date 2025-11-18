namespace SIGEP_ProyectoFinal.Models
{
    public class VacanteListVm
    {
        public int IdVacante { get; set; }
        public string Nombre { get; set; } = "";
        public int IdEmpresa { get; set; }
        public string EmpresaNombre { get; set; } = "";
        public string EspecialidadNombre { get; set; } = "";
        public string Requerimientos { get; set; } = "";
        public int NumCupos { get; set; }
        public int NumPostulados { get; set; }
        public string EstadoNombre { get; set; } = "";
        public int IdModalidad { get; set; }
        public string Descripcion { get; set; } = "";
        public DateTime FechaMaxAplicacion { get; set; }
        public DateTime FechaCierre { get; set; }
        public string Tipo { get; set; } = "";
    }
}
