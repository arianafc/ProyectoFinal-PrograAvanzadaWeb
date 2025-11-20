namespace SIGEP_API.Models
{
    public class DocumentoEvaluacionResponseModel
    {
        public int IdDocumento { get; set; }
        public string NombreArchivo { get; set; } = string.Empty;
        public string Tipo { get; set; } = string.Empty;
        public string FechaSubida { get; set; } = string.Empty;
        public string Extension { get; set; } = string.Empty;
    }
}
