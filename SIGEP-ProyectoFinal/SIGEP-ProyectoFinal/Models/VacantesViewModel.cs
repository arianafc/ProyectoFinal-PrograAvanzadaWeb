using Microsoft.AspNetCore.Mvc.Rendering;

namespace SIGEP_ProyectoFinal.Models
{
    public class VacantesViewModel
    {
        public VacanteModel Vacante { get; set; } = new();

        public IEnumerable<SelectListItem> Estados { get; set; } = new List<SelectListItem>();
        public IEnumerable<SelectListItem> Modalidades { get; set; } = new List<SelectListItem>();
        public IEnumerable<SelectListItem> Especialidades { get; set; } = new List<SelectListItem>();
        public IEnumerable<SelectListItem> Empresas { get; set; } = new List<SelectListItem>();
    }
}
