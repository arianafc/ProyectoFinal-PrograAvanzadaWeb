document.addEventListener("DOMContentLoaded", function () {

    /* =============================
       ALERTAS TEMPDATA
    ============================== */
    const errorInput = document.querySelector(".TempError");
    const successInput = document.querySelector(".TempSuccess");
    const IdComunicado = 0;

    if (successInput && successInput.value) {
        Swal.fire({
            icon: 'success',
            title: 'Éxito',
            text: successInput.value,
            confirmButtonColor: '#2D594D'
        });
    }

    if (errorInput && errorInput.value) {
        Swal.fire({
            icon: 'error',
            title: 'Error',
            text: errorInput.value,
            confirmButtonColor: '#d33'
        });
    }

    /* =============================
       CREAR COMUNICADO
    ============================== */
    const form = document.getElementById('formComunicado');
    if (!form) return;

    form.addEventListener('submit', function (e) {
        e.preventDefault();

        const titulo = form.querySelector('[name="Nombre"]').value.trim();
        const descripcion = form.querySelector('[name="Informacion"]').value.trim();
        const poblacion = form.querySelector('[name="Poblacion"]').value;
        const fechaLimiteInput = form.querySelector('[name="FechaLimite"]');
        let fechaLimite = fechaLimiteInput.value;

        if (!titulo || !descripcion || !poblacion) {
            Swal.fire({
                icon: 'warning',
                title: 'Campos requeridos',
                text: 'Debe completar todos los campos obligatorios.',
                confirmButtonColor: '#2D594D'
            });
            return;
        }

        if (!fechaLimite) {
            const hoy = new Date().toISOString().split('T')[0];

            Swal.fire({
                icon: 'info',
                title: 'Fecha límite no indicada',
                text: 'Se asignará la fecha de hoy.',
                confirmButtonColor: '#2D594D'
            }).then(() => {
                fechaLimiteInput.value = hoy;
                confirmarEnvio(form);
            });
            return;
        }

        confirmarEnvio(form);
    });

    function confirmarEnvio(formulario) {
        Swal.fire({
            title: '¿Guardar comunicado?',
            icon: 'question',
            showCancelButton: true,
            confirmButtonText: 'Sí, guardar',
            cancelButtonText: 'Cancelar',
            confirmButtonColor: '#2D594D'
        }).then((result) => {
            if (result.isConfirmed) {
                formulario.submit();
            }
        });
    }

    /* =============================
       ABRIR MODAL VER COMUNICADO
    ============================== */
    document.querySelectorAll(".btn-abrir-comunicado").forEach(btn => {
        btn.addEventListener("click", function () {
            comunicadoActual = this.dataset.id;
            const id = this.dataset.id;
            const estado = this.dataset.estado; 
          
            const btnEstado = document.getElementById("BtnEliminarComunicado");
            const form = document.getElementById("formEstadoComunicado");
            const inputId = document.getElementById("IdComunicadoEstado");

            if (!btnEstado || !form || !inputId) return;

            inputId.value = id;

            if (estado == 1) {
                // ACTIVO → DESACTIVAR
                btnEstado.innerText = "Inactivar";
                btnEstado.classList.remove("btn-success");
                btnEstado.classList.add("btn-danger");
                form.action = "/Comunicados/DesactivarComunicado";
            } else {
                // INACTIVO → ACTIVAR
                btnEstado.innerText = "Activar";
                btnEstado.classList.remove("btn-danger");
                btnEstado.classList.add("btn-success");
                form.action = "/Comunicados/ActivarComunicado";
            }

            document.getElementById("modalComunicadoUnicoLabel").innerText = this.dataset.titulo;
            document.getElementById("comunicadoDescripcion").innerText = this.dataset.descripcion;
            document.getElementById("comunicadoFecha").innerText = this.dataset.fecha;
            document.getElementById("comunicadoAplicacion").innerText = this.dataset.aplicacion;
            document.getElementById("comunicadoPublicadoPor").innerText = this.dataset.publicado;
            document.getElementById("comunicadoDirigido").innerText = this.dataset.dirigido;

            const contenedorDocs = document.getElementById("comunicadoDocumentos");
            contenedorDocs.innerHTML = "<p>Cargando documentos...</p>";

            fetch(`/Comunicados/ObtenerDetallesComunicado?IdComunicado=${id}`)
                .then(r => r.json())
                .then(data => {

                    if (!data.documentos || data.documentos.length === 0) {
                        contenedorDocs.innerHTML = "<p>No hay documentos disponibles.</p>";
                        return;
                    }

                    let html = "<ul class='list-group'>";
                    data.documentos.forEach(doc => {

                        const urlVer = `/Comunicados/VisualizarDocumento?nombreArchivo=${encodeURIComponent(doc.documento)}`;
                        const urlDesc = `/Comunicados/DescargarDocumento?nombreArchivo=${encodeURIComponent(doc.documento)}`;

                        html += `
                        <li class="list-group-item d-flex justify-content-between align-items-center">
                            ${doc.documento}
                            <div class="btn-group">
                                <a href="${urlVer}" target="_blank" class="btn btn-sm btn-outline-success">
                                    <i class="fas fa-eye"></i>
                                </a>
                                <a href="${urlDesc}" class="btn btn-sm btn-outline-secondary">
                                    <i class="fas fa-download"></i>
                                </a>
                                ${ROL_USUARIO === 2 ? `
                                <button class="btn btn-sm btn-outline-danger btn-eliminar-doc"
                                        data-id="${doc.idDocumento}">
                                    <i class="fas fa-trash"></i>
                                </button>` : ``}
                            </div>
                        </li>`;
                    });

                    html += "</ul>";
                    contenedorDocs.innerHTML = html;
                });
        });
    });

    /* =============================
       EDITAR COMUNICADO
    ============================== */
    document.querySelector(".btnEditarComunicado")?.addEventListener("click", function () {
        if (!comunicadoActual) {
            Swal.fire('Error', 'No se pudo identificar el comunicado.', 'error');
            return;
        }

        console.log(comunicadoActual);
        fetch(`/Comunicados/ObtenerDetallesComunicado?IdComunicado=${comunicadoActual}`)
            .then(r => r.json())
            .then(data => {

                document.getElementById("IdComunicadoEditar").value = data.idComunicado;
                document.getElementById("TituloComunicadoEditar").value = data.nombre;
                document.getElementById("DescripcionComunicadoEditar").value = data.informacion;
                document.getElementById("FechaPublicacionComunicadoEditar").value = data.fecha;
                document.getElementById("FechaAplicacionComunicadoEditar").value = data.fechaLimite || '';
                document.getElementById("DirigidoAComunicadoEditar").value = data.poblacion;

                const contenedor = document.getElementById("documentosActuales");

                if (!data.documentos || data.documentos.length === 0) {
                    contenedor.innerHTML = "<p class='text-muted'>No hay documentos.</p>";
                    return;
                }

                let html = "<ul class='list-group'>";
                data.documentos.forEach(doc => {
                    html += `
<li class="list-group-item d-flex justify-content-between align-items-center">
    <span>${doc.documento}</span>
    <button type="button"
            class="btn btn-sm btn-outline-danger btn-eliminar-doc"
            data-id="${doc.idDocumento}">
        <i class="fas fa-trash"></i>
    </button>
</li>`;
                });
                html += "</ul>";
                contenedor.innerHTML = html;
            });
    });

    const formEditar = document.getElementById("formEditarComunicado");

    if (!formEditar) return;

    formEditar.addEventListener("submit", function (e) {
        e.preventDefault();

        const titulo = document.getElementById("TituloComunicadoEditar").value.trim();
        const descripcion = document.getElementById("DescripcionComunicadoEditar").value.trim();
        const poblacion = document.getElementById("DirigidoAComunicadoEditar").value;
        const fechaLimiteInput = document.getElementById("FechaAplicacionComunicadoEditar");
        let fechaLimite = fechaLimiteInput.value;

        /* =============================
           VALIDACIONES BÁSICAS
        ============================== */

        if (titulo === "") {
            Swal.fire({
                icon: "warning",
                title: "Campo requerido",
                text: "Debe ingresar un título para el comunicado.",
                confirmButtonColor: "#2D594D"
            });
            return;
        }

        if (descripcion === "") {
            Swal.fire({
                icon: "warning",
                title: "Campo requerido",
                text: "Debe ingresar la descripción del comunicado.",
                confirmButtonColor: "#2D594D"
            });
            return;
        }

        if (!poblacion) {
            Swal.fire({
                icon: "warning",
                title: "Campo requerido",
                text: "Debe seleccionar a quién va dirigido el comunicado.",
                confirmButtonColor: "#2D594D"
            });
            return;
        }

        /* =============================
           FECHA LÍMITE
        ============================== */

        if (!fechaLimite) {

            const hoy = new Date();
            const yyyy = hoy.getFullYear();
            const mm = String(hoy.getMonth() + 1).padStart(2, '0');
            const dd = String(hoy.getDate()).padStart(2, '0');
            const fechaHoy = `${yyyy}-${mm}-${dd}`;

            Swal.fire({
                icon: "info",
                title: "Fecha límite no indicada",
                text: "No se seleccionó una fecha límite. Se asignará la fecha de hoy.",
                confirmButtonText: "Entendido",
                confirmButtonColor: "#2D594D"
            }).then(() => {
                fechaLimiteInput.value = fechaHoy;
                confirmarEdicion(formEditar);
            });

            return;
        }

        confirmarEdicion(formEditar);
    });

    /* =============================
       CONFIRMACIÓN FINAL
    ============================== */

    function confirmarEdicion(formulario) {
        Swal.fire({
            title: "¿Guardar cambios?",
            text: "Los cambios del comunicado serán actualizados.",
            icon: "question",
            showCancelButton: true,
            confirmButtonText: "Sí, guardar",
            cancelButtonText: "Cancelar",
            confirmButtonColor: "#2D594D",
            cancelButtonColor: "#6c757d"
        }).then((result) => {
            if (result.isConfirmed) {
                formulario.submit();
            }
        });
    }

    document.getElementById("BtnEliminarComunicado")?.addEventListener("click", function () {

        const form = document.getElementById("formEstadoComunicado");
        const id = document.getElementById("IdComunicadoEstado").value;

        if (!form || !id) return;

        const esActivar = form.action.includes("ActivarComunicado");

        Swal.fire({
            title: "¿Confirmar acción?",
            text: esActivar
                ? "El comunicado será activado"
                : "El comunicado será desactivado",
            icon: "warning",
            showCancelButton: true,
            confirmButtonColor: esActivar ? "#198754" : "#dc3545",
            confirmButtonText: "Sí, confirmar",
            cancelButtonText: "Cancelar"
        }).then(result => {

            if (!result.isConfirmed) return;

            fetch(form.action, {
                method: "POST",
                headers: {
                    "Content-Type": "application/x-www-form-urlencoded",
                    "RequestVerificationToken":
                        document.querySelector('input[name="__RequestVerificationToken"]').value
                },
                body: `IdComunicado=${id}`
            })
                .then(r => r.json())
                .then(resp => {

                    if (resp.success) {
                        Swal.fire({
                            icon: "success",
                            title: "Éxito",
                            text: resp.message,
                            confirmButtonColor: "#2D594D"
                        }).then(() => {
                            location.reload(); 
                        });
                    } else {
                        Swal.fire("Error", resp.message, "error");
                    }

                })
                .catch(() => {
                    Swal.fire("Error", "No se pudo procesar la solicitud.", "error");
                });

        });
    });



    /* =============================
       ELIMINAR DOCUMENTO
    ============================== */
    $(document).on('click', '.btn-eliminar-doc', function () {
        const idDocumento = $(this).data('id');

        Swal.fire({
            title: '¿Eliminar documento?',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#dc3545'
        }).then((result) => {
            if (result.isConfirmed) {
                $.post('/Comunicados/EliminarDocumento', { idDocumento }, function (resp) {
                    if (resp.exito) {
                        Swal.fire('Eliminado', resp.mensaje, 'success');
                        $(`button[data-id="${idDocumento}"]`).closest('li').remove();
                    } else {
                        Swal.fire('Error', resp.mensaje, 'error');
                    }
                });
            }
        });
    });

});
