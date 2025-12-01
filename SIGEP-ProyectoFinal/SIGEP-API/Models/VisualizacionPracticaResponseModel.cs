namespace SIGEP_API.Models
{
    public class VisualizacionPracticaResponseModel
    {
        public int IdVacante { get; set; }
        public string Nombre { get; set; } = string.Empty;
        public string EmpresaNombre { get; set; } = string.Empty;
        public string Requerimientos { get; set; } = string.Empty;
        public DateTime? FechaMaxAplicacion { get; set; }
        public string ModalidadNombre { get; set; } = string.Empty;
        public int IdUsuario { get; set; }
        public string EstudianteNombre { get; set; } = string.Empty;
        public string EstudianteCedula { get; set; } = string.Empty;
        public int EstudianteEdad { get; set; }
        public string EstudianteEspecialidad { get; set; } = string.Empty;
        public string EstudianteCorreo { get; set; } = string.Empty;
        public string ContactoEmpresaNombre { get; set; } = string.Empty;
        public string ContactoEmpresaEmail { get; set; } = string.Empty;
        public string ContactoEmpresaTelefono { get; set; } = string.Empty;
        public int IdPractica { get; set; }
        public DateTime? FechaAplicacion { get; set; }
        public string EstadoPractica { get; set; } = string.Empty;
        public decimal? Nota1 { get; set; }
        public decimal? Nota2 { get; set; }
        public decimal? NotaFinal { get; set; }
    }
}
