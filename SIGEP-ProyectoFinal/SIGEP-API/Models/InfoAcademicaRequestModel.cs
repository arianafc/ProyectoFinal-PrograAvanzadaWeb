using System.ComponentModel.DataAnnotations;

namespace SIGEP_API.Models
{
    public class InfoAcademicaRequestModel
    {
        [Required]

        public int IdUsuario { get; set; }

        [Required]

        public int IdEspecialidad { get; set; }

        [Required]

        public int IdSeccion { get; set; }

    }
}
