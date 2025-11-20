using System.ComponentModel.DataAnnotations;

namespace SIGEP_ProyectoFinal.Models
{
    public class Evaluacion
    {
        public int IdUsuario { get; set; }
        public string Cedula { get; set; } = string.Empty;
        public string NombreCompleto { get; set; } = string.Empty;
        public string Especialidad { get; set; } = string.Empty;
        public string Telefono { get; set; } = string.Empty;
        public string PracticaAsignada { get; set; } = string.Empty;
        public string EstadoAcademico { get; set; } = string.Empty;
        public decimal NotaFinal { get; set; }
        public int IdPractica { get; set; }
        public int? IdVacante { get; set; }
    }

    public class PerfilEstudianteModel
    {
        public int IdUsuario { get; set; }
        public string Cedula { get; set; } = string.Empty;
        public string NombreCompleto { get; set; } = string.Empty;
        public string Nombre { get; set; } = string.Empty;
        public string Apellido1 { get; set; } = string.Empty;
        public string Apellido2 { get; set; } = string.Empty;
        public string Correo { get; set; } = string.Empty;
        public string Telefono { get; set; } = string.Empty;
        public string Direccion { get; set; } = string.Empty;
        public string Sexo { get; set; } = string.Empty;
        public string Especialidad { get; set; } = string.Empty;
        public int Edad { get; set; }
        public string Seccion { get; set; } = string.Empty;
        public string NombreEmpresa { get; set; } = string.Empty;
        public string TelefonoEmpresa { get; set; } = string.Empty;
        public int? IdVacante { get; set; }
        public int IdEstudiante { get; set; }
        public int IdPractica { get; set; }
        public List<ComentarioModel> Comentarios { get; set; } = new List<ComentarioModel>();
    }

    public class ComentarioModel
    {
        public int IdComentario { get; set; }
        public string Autor { get; set; } = string.Empty;
        public string FechaFormateada { get; set; } = string.Empty;
        public string Comentario { get; set; } = string.Empty;
        public string Tipo { get; set; } = string.Empty;
    }

    public class NotasModel
    {
        public decimal Nota1 { get; set; }
        public decimal Nota2 { get; set; }
        public decimal NotaFinal { get; set; }
    }

    public class GuardarNotaModel
    {
        [Required]
        public int IdUsuario { get; set; }

        [Range(0, 100, ErrorMessage = "La Nota 1 debe estar entre 0 y 100")]
        public decimal? Nota1 { get; set; }

        [Range(0, 100, ErrorMessage = "La Nota 2 debe estar entre 0 y 100")]
        public decimal? Nota2 { get; set; }

        public decimal? NotaFinal { get; set; }
    }

    public class GuardarComentarioModel
    {
        [Required]
        public int IdUsuario { get; set; }

        [Required(ErrorMessage = "El comentario es requerido")]
        [StringLength(255, ErrorMessage = "El comentario no puede exceder 255 caracteres")]
        public string Comentario { get; set; } = string.Empty;
    }

    public class DocumentoEvaluacionModel
    {
        public int IdDocumento { get; set; }
        public string NombreArchivo { get; set; } = string.Empty; 
        public string Tipo { get; set; } = string.Empty;
        public string FechaSubida { get; set; } = string.Empty;
        public string Extension { get; set; } = string.Empty;
    }
}
