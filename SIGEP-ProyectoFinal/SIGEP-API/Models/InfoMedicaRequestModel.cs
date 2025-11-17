using System.ComponentModel.DataAnnotations;

namespace SIGEP_API.Models
{
    public class InfoMedicaRequestModel
    {
        [Required]

        public int IdUsuario {  get; set; }

        [Required]

        public string Padecimiento { get; set; } = string.Empty;

        [Required]

        public string Tratamiento {  get; set; } = string.Empty;

        [Required]

        public string Alergia {  get; set; } = string.Empty;




    }
}
