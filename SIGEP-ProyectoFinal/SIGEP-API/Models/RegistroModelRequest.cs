using System.ComponentModel.DataAnnotations;

namespace SIGEP_API.Models
{
    public class RegistroModelRequest
    {
        [Required]

        public string? Cedula { get; set; }

        [Required]
        public string? Contrasenna { get; set; }
        [Required]
        public string? Correo { get; set; }
        [Required]
        public string? Nombre { get; set; }
        [Required]
        public int IdEspecialidad { get; set; }

        [Required]

        public int IdSeccion { get; set; }

        [Required]

        public string? Apellido1 { get; set; }

        [Required]

        public string? Apellido2 { get; set; }

        [Required]

        public DateTime? FechaNacimiento { get; set; }

    }
}
