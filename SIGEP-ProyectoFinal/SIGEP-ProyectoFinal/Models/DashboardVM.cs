namespace SIGEP_ProyectoFinal.Models
{
    public class DashboardVM
    {
        public int EstudiantesActivos { get; set; }

        public int EstudiantesConPractica { get; set; }

        public int EstudiantesSinPractica { get; set; }

        public int PracticasFinalizadas { get; set; }

        public int EmpresasRegistradas { get; set; }

        public int PracticasAsignadas { get; set; }

        public List<UltimasPracticasAsignadasDTO> UltimasPracticasAsignadas { get; set; } = new List<UltimasPracticasAsignadasDTO>();

    }
}
