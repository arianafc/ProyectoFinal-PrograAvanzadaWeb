namespace SIGEP_ProyectoFinal.Models
{
    public class VacanteCrearEditarVm
    {
        public int IdVacante { get; set; }
        public string Nombre { get; set; } = "";
        public int IdEmpresa { get; set; }
        public int IdEspecialidad { get; set; }
        public int NumCupos { get; set; }
        public int IdModalidad { get; set; }
        public string Requisitos { get; set; } = "";
        public string Descripcion { get; set; } = "";
        public string FechaMaxAplicacion { get; set; } = "";
        public string FechaCierre { get; set; } = "";
    }
}
