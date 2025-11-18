namespace SIGEP_ProyectoFinal.Models
{
    public class VacanteModel
    {
        public int IdVacante { get; set; }
        public string Nombre { get; set; } = "";
        public int IdEmpresa { get; set; }
        public int IdEspecialidad { get; set; }
        public int NumCupos { get; set; }
        public int IdModalidad { get; set; }
        public string Requerimientos { get; set; } = "";
        public string Descripcion { get; set; } = "";
        public DateTime FechaMaxAplicacion { get; set; }
        public DateTime FechaCierre { get; set; }
    }
}
