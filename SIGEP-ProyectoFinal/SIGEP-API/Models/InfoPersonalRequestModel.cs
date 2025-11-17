using System.ComponentModel.DataAnnotations;

namespace SIGEP_API.Models
{
    public class InfoPersonalRequestModel
    {
        [Required]

        public int IdUsuario { get; set; }
        [Required]

        public string? Nombre { get; set; }

        [Required]

        public string? Apellido1 { get; set; }

        [Required]

        public string? Apellido2 { get; set; }

       [Required]
        public string? Cedula { get; set; }

        [Required]
        public string? Correo { get; set; }

        [Required]

        public string? Telefono { get; set; }

        [Required]

        public DateTime? FechaNacimiento { get; set; }

       [Required]
        public string? Sexo { get; set; }

        [Required]
        public string? Nacionalidad { get; set; }

        [Required]
        public string? Provincia { get; set; }

        [Required]
        public string? Distrito { get; set; }

        [Required]
        public string? Canton { get; set; }

        [Required]
        public string? DireccionExacta { get; set; }


    }
}
