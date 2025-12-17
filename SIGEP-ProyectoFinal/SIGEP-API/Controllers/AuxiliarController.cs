using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace SIGEP_API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuxiliarController : ControllerBase
    {
        private readonly IConfiguration _config;
        public AuxiliarController(IConfiguration config) => _config = config;

        private SqlConnection Conn() =>
            new SqlConnection(_config.GetConnectionString("BDConnection"));

        [HttpGet("Estados")]
        public IActionResult Estados()
        {
            using var cn = Conn();
            var data = cn.Query<dynamic>(
                "SELECT CAST(IdEstado AS VARCHAR(10)) AS value, Descripcion AS text FROM Estados WHERE IdEstado > 0"
            );
            return Ok(data);
        }

        [HttpGet("Especialidades")]
        
        public IActionResult Especialidades()
        {
            using var cn = Conn();
            var data = cn.Query<dynamic>(
                "SELECT CAST(IdEspecialidad AS VARCHAR(10)) AS value, Nombre AS text FROM Especialidades"
            );
            return Ok(data);
        }

        [HttpGet("Empresas")]
        public IActionResult Empresas()
        {
            using var cn = Conn();
            var data = cn.Query<dynamic>(
                "SELECT CAST(IdEmpresa AS VARCHAR(10)) AS value, NombreEmpresa AS text FROM Empresas WHERE IdEstado = 1"
            );
            return Ok(data);
        }

        [HttpGet("Modalidades")]
        public IActionResult Modalidades()
        {
            using var cn = Conn();
            var data = cn.Query<dynamic>(
                "SELECT CAST(IdModalidad AS VARCHAR(10)) AS value, Descripcion AS text FROM Modalidades"
            );
            return Ok(data);
        }
    }
}
