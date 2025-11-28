namespace SIGEP_API.Models
{
    public class DatosUsuarioResponseModel
    {
        public int IdUsuario { get; set; }
        public string Nombre { get; set; } = string.Empty;
        public string Cedula { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Rol { get; set; } = string.Empty;
        public string Estado { get; set; } = string.Empty;
        public int IdEstado { get; set; }
    }
}
