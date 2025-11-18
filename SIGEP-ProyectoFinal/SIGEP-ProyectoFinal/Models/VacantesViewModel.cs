using Microsoft.AspNetCore.Mvc.Rendering;

namespace SIGEP_ProyectoFinal.Models
{
    public class VacantesViewModel
    {
        public VacanteModel Vacante { get; set; } = new();

        public IEnumerable<SelectListItem> Estados { get; set; } = [];
        public IEnumerable<SelectListItem> Modalidades { get; set; } = [];
        public IEnumerable<SelectListItem> Especialidades { get; set; } = [];
        public IEnumerable<SelectListItem> Empresas { get; set; } = [];
    }
}
