using System.ComponentModel.DataAnnotations;

namespace SIGEP_API.Models
{
    public class CambioContrasennaRequestModel
    {
        [Required]

        public int IdUsuario { get; set; }

        [Required]

        public string? Contrasenna { get; set; }

        [Required]

        public string? ConfirmarContrasenna { get; set; }

    }
}
