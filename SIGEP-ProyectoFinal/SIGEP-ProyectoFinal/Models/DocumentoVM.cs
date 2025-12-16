namespace SIGEP_ProyectoFinal.Models
{
    public class DocumentoVM
    {
        public int IdDocumento { get; set; }
        public string? Documento { get; set; }

        public string? NombreArchivo { get; set; }
        public string? Tipo { get; set; }
        public DateTime FechaSubida { get; set; }

        public int IdComunicado { get; set; }

        public int IdUsuario { get; set; }  

    }
}
