(function () {

    let tabla;
    let dataCR = null;

    // ======================================================
    // 1. Cargar JSON solo una vez
    // ======================================================
    async function cargarCR() {
        if (dataCR) return;

        try {
            const resp = await fetch("/json/costarica.json");
            dataCR = await resp.json();
        } catch (e) {
            console.error("❌ Error cargando costarica.json", e);
        }
    }

    // ======================================================
    // 2. Provincias
    // ======================================================
    function llenarProvincias(idSelect) {
        const sel = document.getElementById(idSelect);
        sel.innerHTML = `<option value="">Seleccione una provincia</option>`;

        Object.keys(dataCR.provincias).forEach(k => {
            let nombre = dataCR.provincias[k].nombre;
            sel.innerHTML += `<option value="${nombre}">${nombre}</option>`;
        });
    }

    // ======================================================
    // 3. Cantones
    // ======================================================
    function llenarCantones(idProvincia, idCant, idDist) {
        const prov = document.getElementById(idProvincia).value;
        const cant = document.getElementById(idCant);
        const dist = document.getElementById(idDist);

        cant.innerHTML = `<option value="">Seleccione un cantón</option>`;
        dist.innerHTML = `<option value="">Seleccione un distrito</option>`;

        if (!prov) return;

        const provKey = Object.keys(dataCR.provincias).find(k => dataCR.provincias[k].nombre === prov);
        const cantones = dataCR.provincias[provKey].cantones;

        Object.keys(cantones).forEach(k => {
            cant.innerHTML += `<option value="${cantones[k].nombre}">${cantones[k].nombre}</option>`;
        });
    }

    // ======================================================
    // 4. Distritos
    // ======================================================
    function llenarDistritos(idProvincia, idCanton, idDistrito) {
        const prov = document.getElementById(idProvincia).value;
        const cant = document.getElementById(idCanton).value;
        const dist = document.getElementById(idDistrito);

        dist.innerHTML = `<option value="">Seleccione un distrito</option>`;

        if (!prov || !cant) return;

        const provKey = Object.keys(dataCR.provincias)
            .find(k => dataCR.provincias[k].nombre === prov);

        const cantones = dataCR.provincias[provKey].cantones;

        const cantKey = Object.keys(cantones)
            .find(k => cantones[k].nombre === cant);

        const distritos = cantones[cantKey].distritos;

        Object.keys(distritos).forEach(k => {
            dist.innerHTML += `<option value="${distritos[k]}">${distritos[k]}</option>`;
        });
    }

    // ======================================================
    // 5. Inicializar modal Agregar
    // ======================================================
    async function initAgregar() {
        await cargarCR();

        llenarProvincias("provinciaEmpresa");

        document.getElementById("provinciaEmpresa").onchange = () =>
            llenarCantones("provinciaEmpresa", "cantonEmpresa", "distritoEmpresa");

        document.getElementById("cantonEmpresa").onchange = () =>
            llenarDistritos("provinciaEmpresa", "cantonEmpresa", "distritoEmpresa");
    }

    // ======================================================
    // 6. Inicializar modal Editar
    // ======================================================
    async function initEditar() {
        await cargarCR();
        llenarProvincias("provinciaEmpresaEditar");

        const p = document.getElementById("provinciaEmpresaEditar").getAttribute("data-selected");
        const c = document.getElementById("cantonEmpresaEditar").getAttribute("data-selected");
        const d = document.getElementById("distritoEmpresaEditar").getAttribute("data-selected");

        if (p) {
            document.getElementById("provinciaEmpresaEditar").value = p;
            llenarCantones("provinciaEmpresaEditar", "cantonEmpresaEditar", "distritoEmpresaEditar");
        }

        if (c) {
            document.getElementById("cantonEmpresaEditar").value = c;
            llenarDistritos("provinciaEmpresaEditar", "cantonEmpresaEditar", "distritoEmpresaEditar");
        }

        if (d) {
            document.getElementById("distritoEmpresaEditar").value = d;
        }
    }

    // ======================================================
    // 7. DataTable
    // ======================================================
    function initTabla() {
        tabla = $('#tablaEmpresas').DataTable({
            ajax: {
                url: window.EMPRESA_URLS.listar,
                type: 'GET',
                dataSrc: 'data'
            },
            columns: [
                { data: 'nombreEmpresa' },
                { data: 'areasAfines' },
                { data: 'ubicacion' },
                {
                    data: 'historialVacantes',
                    render: x => `${x || 0} vacantes anteriores`
                },
                {
                    data: 'idEmpresa',
                    render: (id, type, row) =>
                        `<button class="btn btn-editar-empresa" data-id="${id}">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-eliminar-empresa" data-id="${id}" data-nombre="${row.NombreEmpresa}">
                            <i class="fas fa-trash"></i>
                        </button>`
                }
            ]
        });
    }

    // ======================================================
    // 8. GUARDAR EMPRESA  
    // ======================================================
    $(document).on("click", "#BtnGuardarEmpresa", function () {

        const p = {
            NombreEmpresa: $("#nombreEmpresa").val(),
            NombreContacto: $("#nombreContacto").val(),
            Email: $("#emailContacto").val(),
            Telefono: $("#telefonoContacto").val(),
            Provincia: $("#provinciaEmpresa").val(),
            Canton: $("#cantonEmpresa").val(),
            Distrito: $("#distritoEmpresa").val(),
            DireccionExacta: $("#direccion").val(),
            AreasAfinidad: $("#areas").val()
        };

        $.post(window.EMPRESA_URLS.crear, p)
            .done(r => {
                if (r.ok) {
                    Swal.fire("Éxito", "Empresa creada correctamente", "success");
                    tabla.ajax.reload();
                    $("#ModalAgregarEmpresa").modal("hide");
                } else {
                    Swal.fire("Error", r.msg, "error");
                }
            })
            .fail(() => Swal.fire("Error", "No se pudo guardar la empresa", "error"));
    });

    // ======================================================
    // 9. ABRIR EDITAR
    // ======================================================
    $(document).on("click", ".btn-editar-empresa", function () {
        const id = $(this).data("id");

        $.get(window.EMPRESA_URLS.getById, { id })
            .done(r => {
                if (!r.ok) return Swal.fire("Error", "Empresa no encontrada", "error");

                const e = r.data;  // JSON camelCase

                $("#empresaIdEditar").val(e.IdEmpresa);
                $("#nombreEmpresaEditar").val(e.NombreEmpresa);
                $("#contactoEmpresaEditar").val(e.NombreContacto);
                $("#emailEmpresaEditar").val(e.Email);
                $("#telefonoEmpresaEditar").val(e.Telefono);

                $("#provinciaEmpresaEditar").attr("data-selected", e.Provincia);
                $("#cantonEmpresaEditar").attr("data-selected", e.Canton);
                $("#distritoEmpresaEditar").attr("data-selected", e.Distrito);

                $("#direccionEmpresaEditar").val(e.DireccionExacta);
                $("#areasEmpresaEditar").val(e.AreasAfinidad);

                $("#ModalEditarEmpresa").modal("show");
            });
    });

    // ======================================================
    // 10. GUARDAR CAMBIOS
    // ======================================================
    $(document).on("click", "#btnGuardarCambiosEmpresa", function () {

        const p = {
            IdEmpresa: $("#empresaIdEditar").val(),
            NombreEmpresa: $("#nombreEmpresaEditar").val(),
            NombreContacto: $("#contactoEmpresaEditar").val(),
            Email: $("#emailEmpresaEditar").val(),
            Telefono: $("#telefonoEmpresaEditar").val(),
            Provincia: $("#provinciaEmpresaEditar").val(),
            Canton: $("#cantonEmpresaEditar").val(),
            Distrito: $("#distritoEmpresaEditar").val(),
            DireccionExacta: $("#direccionEmpresaEditar").val(),
            AreasAfinidad: $("#areasEmpresaEditar").val()
        };

        $.post(window.EMPRESA_URLS.editar, p)
            .done(r => {
                if (r.ok) {
                    Swal.fire("Éxito", "Cambios guardados correctamente", "success");
                    tabla.ajax.reload();
                    $("#ModalEditarEmpresa").modal("hide");
                } else {
                    Swal.fire("Error", r.msg, "error");
                }
            })
            .fail(() => Swal.fire("Error", "No se pudo actualizar", "error"));
    });

    // ======================================================
    // 11. ELIMINAR
    // ======================================================
    $(document).on("click", ".btn-eliminar-empresa", function () {

        const id = $(this).data("id");
        const nombre = $(this).data("nombre");

        Swal.fire({
            title: "Eliminar Empresa",
            text: `¿Desea eliminar: ${nombre}?`,
            icon: "warning",
            showCancelButton: true,
            confirmButtonText: "Sí, eliminar",
            cancelButtonText: "Cancelar"
        }).then(res => {

            if (!res.isConfirmed) return;

            $.post(window.EMPRESA_URLS.eliminar, { id })
                .done(r => {
                    Swal.fire("Éxito", "Empresa eliminada", "success");
                    tabla.ajax.reload();
                })
                .fail(() => Swal.fire("Error", "No se pudo eliminar", "error"));
        });
    });

    // ======================================================
    // Inicialización
    // ======================================================
    $(document).ready(initTabla);

    $("#ModalAgregarEmpresa").on("shown.bs.modal", initAgregar);
    $("#ModalEditarEmpresa").on("shown.bs.modal", initEditar);

})();
