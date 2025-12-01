namespace SIGEP_ProyectoFinal.Models
{
    public class VacantePracticaModel
    {
        public int IdVacante { get; set; }
        public string? Nombre { get; set; }
        public string? EmpresaNombre { get; set; }
        public string? Requerimientos { get; set; }
        public DateTime? FechaMaxAplicacion { get; set; }
        public string? ModalidadNombre { get; set; }
        public int IdUsuario { get; set; }
        public string? EstudianteNombre { get; set; }
        public string? EstudianteCedula { get; set; }
        public int EstudianteEdad { get; set; }
        public string? EstudianteEspecialidad { get; set; }
        public string? EstudianteCorreo { get; set; }
        public string? ContactoEmpresaNombre { get; set; }
        public string? ContactoEmpresaEmail { get; set; }
        public string? ContactoEmpresaTelefono { get; set; }
        public int IdPractica { get; set; }
        public DateTime? FechaAplicacion { get; set; }
        public string? EstadoPractica { get; set; }
        public decimal? Nota1 { get; set; }
        public decimal? Nota2 { get; set; }
        public decimal? NotaFinal { get; set; }

        public List<ComentarioPracticaModel> Comentarios { get; set; } = new List<ComentarioPracticaModel>();
        public List<EstadoPracticaModel> ListaEstados { get; set; } = new List<EstadoPracticaModel>();

        public class ComentarioPracticaModel
        {
            public int Id { get; set; }
            public DateTime Fecha { get; set; }
            public string Usuario { get; set; } = string.Empty;
            public string Comentario { get; set; } = string.Empty;
        }
        public class EstadoPracticaModel
        {
            public int IdEstado { get; set; }
            public string Descripcion { get; set; } = string.Empty;
        }

    }
}
