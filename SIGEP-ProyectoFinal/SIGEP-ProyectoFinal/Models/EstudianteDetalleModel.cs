namespace SIGEP_ProyectoFinal.Models
{
    public class EstudianteDetalleModel
    {
        // Información personal
        public string Cedula { get; set; } = "";
        public string Nombre { get; set; } = "";
        public string Apellido1 { get; set; } = "";
        public string Apellido2 { get; set; } = "";
        public string Correo { get; set; } = "";
        public string Telefono { get; set; } = "";
        public DateTime? FechaNacimiento { get; set; }

        // Dirección
        public string Provincia { get; set; } = "";
        public string Canton { get; set; } = "";
        public string Distrito { get; set; } = "";
        public string DireccionExacta { get; set; } = "";

        // Académico
        public string Especialidad { get; set; } = "";
        public string Seccion { get; set; } = "";

        // Listas relacionadas
        public List<EncargadoModel> Encargados { get; set; } = new List<EncargadoModel>();
        public List<DocumentoModel> Documentos { get; set; } = new List<DocumentoModel>();
        public List<PracticaModel> Practicas { get; set; } = new List<PracticaModel>();
    }

    // Modelo para encargados
    public class EncargadoModel
    {
        public string Nombre { get; set; } = "";
        public string Telefono { get; set; } = "";
        public string Ocupacion { get; set; } = "";
    }

    // Modelo para documentos
    public class DocumentoModel
    {
        public int IdDocumento { get; set; }
        public string Documento { get; set; } = "";
    }

    // Modelo para prácticas/postulaciones
    public class PracticaModel
    {
        public int IdPostulacion { get; set; }
        public int IdVacante { get; set; }
        public int IdUsuario { get; set; }
        public string Empresa { get; set; } = "";
        public string Estado { get; set; } = "";
    }

    // Modelo para especialidades
    public class EspecialidadModel
    {
        public int IdEspecialidad { get; set; }
        public string Nombre { get; set; } = "";
    }
}

