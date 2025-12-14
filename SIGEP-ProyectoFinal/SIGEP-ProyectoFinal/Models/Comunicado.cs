namespace SIGEP_ProyectoFinal.Models
{
    public class Comunicado
    {
        public int Id { get; set; }
        public string? Nombre { get; set; }
        public DateTime Fecha { get; set; }
        public DateTime? FechaLimite{ get; set; }
        public string? Informacion{ get; set; }
        public int  IdUsuario{ get; set; }
        public string? PublicadoPor { get; set; }

        public string? Poblacion { get; set; }
        public List<Comunicado> AllComunicados { get; set; } = new List<Comunicado>();

        public List<Comunicado> ComunicadosEstudiantes { get; set; } = new List<Comunicado>();

        public List<Comunicado> ComunicadosAdmin { get; set; } = new List<Comunicado>();
    }
}
