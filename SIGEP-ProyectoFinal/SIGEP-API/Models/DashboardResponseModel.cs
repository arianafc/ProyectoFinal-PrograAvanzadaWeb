using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace SIGEP_API.Models
{
    public class DashboardResponseModel
    {
        public int EstudiantesActivos { get; set; }

        public int EstudiantesConPractica { get; set; }

        public int EstudiantesSinPractica { get; set; }

        public int PracticasFinalizadas { get; set; }

        public int EmpresasRegistradas { get; set; }

        public int PracticasAsignadas { get; set; }

        public string? Estudiante { get; set; }

        public string? NombreEmpresa { get; set; }

        public string? Estado { get; set; }

        public string? Especialidad { get; set; }

        public DateTime? FechaAplicacion { get; set; }
    }
}
