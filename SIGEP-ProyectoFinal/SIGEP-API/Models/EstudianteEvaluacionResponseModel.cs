namespace SIGEP_API.Models
{
    public class EstudianteEvaluacionResponseModel
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
}
