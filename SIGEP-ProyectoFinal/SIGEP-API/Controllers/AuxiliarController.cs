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

        // ===================== ESTADOS =====================
        [HttpGet("Estados")]
        public IActionResult Estados()
        {
            using var cn = Conn();
            var data = cn.Query<dynamic>(
                "SELECT IdEstado AS Value, Descripcion AS Text FROM Estados"
            );
            return Ok(data);
        }

        // ===================== ESPECIALIDADES =====================
        [HttpGet("Especialidades")]
        public IActionResult Especialidades()
        {
            using var cn = Conn();
            var data = cn.Query<dynamic>(
                "SELECT IdEspecialidad AS Value, Nombre AS Text FROM Especialidades"
            );
            return Ok(data);
        }

        // ===================== EMPRESAS =====================
        [HttpGet("Empresas")]
        public IActionResult Empresas()
        {
            using var cn = Conn();
            var data = cn.Query<dynamic>(
                "SELECT IdEmpresa AS Value, NombreEmpresa AS Text FROM Empresas"
            );
            return Ok(data);
        }

        // ===================== MODALIDADES =====================
        [HttpGet("Modalidades")]
        public IActionResult Modalidades()
        {
            using var cn = Conn();
            var data = cn.Query<dynamic>(
                "SELECT IdModalidad AS Value, Descripcion AS Text FROM Modalidades"
            );
            return Ok(data);
        }
    }
}

