namespace SIGEP_ProyectoFinal.Models
{
    public class Comunicado
    {
        public int IdComunicado { get; set; }
        public string? Nombre { get; set; }
        public DateTime Fecha { get; set; }
        public DateTime? FechaLimite{ get; set; }
        public string? Informacion{ get; set; }
        public int  IdUsuario{ get; set; }
        public string? PublicadoPor { get; set; }

        public int IdEstado { get; set; }
        public string? Poblacion { get; set; }
        public List<Comunicado> AllComunicados { get; set; } = new List<Comunicado>();

        public List<Comunicado> ComunicadosEstudiantes { get; set; } = new List<Comunicado>();

        public List<Comunicado> ComunicadosAdmin { get; set; } = new List<Comunicado>();

        public List<DocumentoVM> Documentos { get; set; } = new List<DocumentoVM>();
    }
}
