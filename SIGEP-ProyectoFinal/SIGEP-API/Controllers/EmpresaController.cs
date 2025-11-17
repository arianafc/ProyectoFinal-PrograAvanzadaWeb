using Dapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using SIGEP_API.Models;
using System.Data;

namespace SIGEP_API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class EmpresaController : ControllerBase
    {
        private readonly IConfiguration _config;

        public EmpresaController(IConfiguration config)
        {
            _config = config;
        }

        private SqlConnection Conn() =>
            new SqlConnection(_config["ConnectionStrings:BDConnection"]);

        // ============================================================
        // CONSULTAR EMPRESA POR ID  (GET)
        // ============================================================
        [HttpGet]
        [Route("ConsultarEmpresas")]
        public IActionResult ConsultarEmpresas(int IdEmpresa)
        {
            using (var db = Conn())
            {
                var p = new DynamicParameters();
                p.Add("@IdEmpresa", IdEmpresa);

                var data = db.Query<EmpresaDetalleModel>(
                    "ConsultarEmpresaSP",
                    p,
                    commandType: CommandType.StoredProcedure
                );

                return Ok(data);
            }
        }

        // ============================================================
        // CONSULTAR LISTA (DataTable)
        // ============================================================
        [HttpGet]
        [Route("ListarEmpresas")]
        public IActionResult ListarEmpresas()
        {
            using (var db = Conn())
            {
                var data = db.Query<EmpresaListItemModel>(
                    "ListarEmpresasSP",
                    commandType: CommandType.StoredProcedure
                );

                return Ok(data);
            }
        }

        // ============================================================
        // AGREGAR EMPRESA (POST)
        // ============================================================
        [HttpPost]
        [Route("AgregarEmpresa")]
        public IActionResult AgregarEmpresa(EmpresaGuardarRequestModel m)
        {
            using (var db = Conn())
            {
                var p = new DynamicParameters();
                p.Add("@IdEmpresa", 0);
                p.Add("@NombreEmpresa", m.NombreEmpresa);
                p.Add("@NombreContacto", m.NombreContacto);
                p.Add("@Email", m.Email);
                p.Add("@Telefono", m.Telefono);
                p.Add("@Provincia", m.Provincia);
                p.Add("@Canton", m.Canton);
                p.Add("@Distrito", m.Distrito);
                p.Add("@DireccionExacta", m.DireccionExacta);
                p.Add("@AreasAfinidad", m.AreasAfinidad);

                p.Add("@IdEmpresaOut", dbType: DbType.Int32, direction: ParameterDirection.Output);

                db.Execute("GuardarEmpresaSP", p, commandType: CommandType.StoredProcedure);

                int idGenerado = p.Get<int>("@IdEmpresaOut");

                return Ok(new { ok = true, id = idGenerado });
            }
        }

        // ============================================================
        // ACTUALIZAR EMPRESA
        // ============================================================
        [HttpPost]
        [Route("ActualizarEmpresa")]
        public IActionResult ActualizarEmpresa(EmpresaGuardarRequestModel m)
        {
            using (var db = Conn())
            {
                var p = new DynamicParameters();

                p.Add("@IdEmpresa", m.IdEmpresa);
                p.Add("@NombreEmpresa", m.NombreEmpresa);
                p.Add("@NombreContacto", m.NombreContacto);
                p.Add("@Email", m.Email);
                p.Add("@Telefono", m.Telefono);
                p.Add("@Provincia", m.Provincia);
                p.Add("@Canton", m.Canton);
                p.Add("@Distrito", m.Distrito);
                p.Add("@DireccionExacta", m.DireccionExacta);
                p.Add("@AreasAfinidad", m.AreasAfinidad);


                db.Execute("ActualizarEmpresaSP", p, commandType: CommandType.StoredProcedure);

                return Ok(new { ok = true });
            }
        }

        // ============================================================
        // ELIMINAR EMPRESA (POST)
        // ============================================================
        [HttpPost]
        [Route("EliminarEmpresa")]
        public IActionResult EliminarEmpresa(EmpresaEliminarRequest m)
        {
            using (var db = Conn())
            {
                var p = new DynamicParameters();
                p.Add("@IdEmpresa", m.Id);

                db.Execute("EliminarEmpresaSP", p, commandType: CommandType.StoredProcedure);

                return Ok(new { ok = true });
            }
        }
    }
}

