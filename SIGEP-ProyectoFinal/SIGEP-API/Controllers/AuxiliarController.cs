using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using System.Data;

namespace SIGEP_API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuxiliarController : ControllerBase
    {
        private readonly IConfiguration _config;

        public AuxiliarController(IConfiguration config)
        {
            _config = config;
        }

        private SqlConnection Conn() =>
            new SqlConnection(_config.GetConnectionString("BDConnection"));

        // ============================================================
        // OBTENER ESTADOS
        // ============================================================
        [HttpGet("Estados")]
        public IActionResult Estados()
        {
            try
            {
                using (var db = Conn())
                {
                    var data = db.Query<dynamic>(
                        "ObtenerEstadosSP",
                        commandType: CommandType.StoredProcedure
                    );

                    return Ok(data);
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al obtener estados", detalle = ex.Message });
            }
        }

        // ============================================================
        // OBTENER ESPECIALIDADES
        // ============================================================
        [HttpGet("Especialidades")]
        public IActionResult Especialidades()
        {
            try
            {
                using (var db = Conn())
                {
                    var data = db.Query<dynamic>(
                        "ObtenerEspecialidadesListaSP",
                        commandType: CommandType.StoredProcedure
                    );

                    return Ok(data);
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al obtener especialidades", detalle = ex.Message });
            }
        }

        // ============================================================
        // OBTENER EMPRESAS
        // ============================================================
        [HttpGet("Empresas")]
        public IActionResult Empresas()
        {
            try
            {
                using (var db = Conn())
                {
                    var data = db.Query<dynamic>(
                        "ObtenerEmpresasListaSP",
                        commandType: CommandType.StoredProcedure
                    );

                    return Ok(data);
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al obtener empresas", detalle = ex.Message });
            }
        }

        // ============================================================
        // OBTENER MODALIDADES
        // ============================================================
        [HttpGet("Modalidades")]
        public IActionResult Modalidades()
        {
            try
            {
                using (var db = Conn())
                {
                    var data = db.Query<dynamic>(
                        "ObtenerModalidadesSP",
                        commandType: CommandType.StoredProcedure
                    );

                    return Ok(data);
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al obtener modalidades", detalle = ex.Message });
            }
        }
    }
}