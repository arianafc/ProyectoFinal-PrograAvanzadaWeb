(function () {

    let tabla;
    const CFG = window.EstuCfg || { rol: 0, urls: {} };

    function redirSiLogin(res, xhr) {
        try {
            if (typeof res !== 'string') return false;
            var urlLogin = CFG.urls.login || '';
            var looksLikeLogin =
                res.indexOf('id="formLogin"') >= 0 ||
                (urlLogin && res.indexOf('action="' + urlLogin + '"') >= 0) ||
                /Iniciar sesi[óo]n/i.test(res);
            var isFullDoc = res.indexOf('<!DOCTYPE html') >= 0 && /login/i.test(res);
            if (looksLikeLogin || isFullDoc) {
                window.location.href = urlLogin;
                return true;
            }
        } catch (e) { }
        return false;
    }

    var rol = parseInt(CFG.rol || 0, 10);

    function crearBadge(clase, texto) {
        var estilos = {
            'badge-aprobado': 'background-color: #768C46; color: white;',
            'badge-rezagado': 'background-color: #E57373; color: white;',
            'badge-no-asignada': 'background-color: #f2f2f2; color: #2d594d; border: 1px solid #ddd;',
            'badge-procesos-activos': 'background-color: #F2C94C; color: #2D594D; box-shadow: 0 1px 2px rgba(0,0,0,0.1);',
            'badge-en-progreso': 'background-color: #F5B97A; color: #2D594D;',
            'badge-rechazada': 'background-color: #f8d7da; color: #721c24;',
            'badge-asignada': 'background-color: #768C46; color: white;',
            'badge-aprobada': 'background-color: #d4edda; color: #155724;',
            'badge-retirada': 'background-color: #f5c6cb; color: #721c24;',
            'badge-finalizada': 'background-color: #e2e3e5; color: #383d41;',
            'badge-archivado': 'background-color: #e2e3e5; color: #383d41;',
            'badge-en-curso': 'background-color: #d1ecf1; color: #0c5460;',
            'badge-en-proceso': 'background-color: #F5B97A; color: #2D594D;'
        };

        var estiloBase = 'display: inline-block; padding: 0.35em 0.65em; border-radius: 0.25rem; font-size: 14px; font-weight: bold; text-align: center; min-width: 90px;';
        var estiloEspecifico = estilos[clase] || '';

        return '<span class="badge ' + clase + '" style="' + estiloBase + ' ' + estiloEspecifico + '">' + texto + '</span>';
    }

    function initTabla() {
        tabla = $('#tablaEstudiantes').DataTable({
            ajax: {
                url: CFG.urls.get,
                data: function (d) {
                    d.estado = $('#filtroEstado').val();
                    var $esp = $('#filtroEspecialidad');
                    d.idEspecialidad = $esp.length ? ($esp.val() || 0) : 0;
                },
                dataSrc: 'data'
            },
            columns: [
                { data: 'cedula' },  // ⭐ minúscula
                { data: 'nombreCompleto' },  // ⭐ camelCase
                { data: 'especialidadNombre' },  // ⭐ camelCase
                { data: 'telefono' },  // ⭐ minúscula
                {
                    data: 'estadoAcademico',  // ⭐ camelCase
                    render: function (data) {
                        if (data === true) {
                            return crearBadge('badge-aprobado', 'Aprobada');
                        } else if (data === false) {
                            return crearBadge('badge-rezagado', 'Rezagado');
                        } else {
                            return crearBadge('badge-no-asignada', 'Sin Estado');
                        }
                    }
                },
                {
                    data: 'estadoPractica',  // ⭐ camelCase
                    render: function (data) {
                        var estado = (data || '').toString().trim().toLowerCase();

                        var procesosActivos = [
                            'asignada',
                            'en curso',
                            'en proceso de aplicacion',
                            'aprobada',
                            'rechazada',
                            'retirada',
                            'finalizada',
                            'rezagado',
                            'archivado',
                            'en progreso'
                        ];

                        var tieneProcesoActivo = procesosActivos.some(e => estado.includes(e));

                        if (tieneProcesoActivo) {
                            return crearBadge('badge-procesos-activos', 'Con Procesos Activos');
                        } else {
                            return crearBadge('badge-no-asignada', 'Sin Procesos Activos');
                        }
                    }
                },
                {
                    data: 'idUsuario',  // ⭐ camelCase
                    render: function (data, type, row) {
                        var html =
                            '<button class="btn bg-transparent btn-accion verPerfil" data-id="' + data + '" style="color:#2d594d" title="Ver perfil">' +
                            '<i class="fas fa-eye"></i>' +
                            '</button>';
                        if (rol === 2 || rol === 3) {
                            html +=
                                '<button class="btn bg-transparent btn-accion btn-actualizar-estado" data-id="' + data + '" data-estado="' + (row.idEstado || 0) + '" style="color:#2d594d" title="Actualizar estado">' +  // ⭐ camelCase
                                '<i class="fas fa-sync-alt"></i>' +
                                '</button>';
                        }
                        return html;
                    }
                }
            ],
            columnDefs: [{ targets: -1, orderable: false, searchable: false, width: "100px" }],
            language: {
                url: '//cdn.datatables.net/plug-ins/1.13.6/i18n/es-ES.json'
            }
        });
    }

    $('#filtroEstado').on('change', function () {
        if (tabla) tabla.ajax.reload();
    });

    if ($('#filtroEspecialidad').length) {
        $('#filtroEspecialidad').on('change', function () {
            if (tabla) tabla.ajax.reload();
        });
    }

    $(document).on('click', '.verPerfil', function () {
        const id = $(this).data('id');
        const modalPerfilEl = document.getElementById('modalPerfil');
        const modalPerfil = bootstrap.Modal.getOrCreateInstance(modalPerfilEl);

        $('#perfilBody').html(
            '<div class="text-center p-3">' +
            '<div class="spinner-border text-success" role="status"></div>' +
            '<p class="mt-2 text-muted">Cargando perfil...</p>' +
            '</div>'
        );

        $.ajax({
            url: CFG.urls.detalle,
            type: 'GET',
            data: { id: id },
            success: function (html, _status, xhr) {
                if (redirSiLogin(html, xhr)) return;
                if (!html || html.trim() === "") {
                    $('#perfilBody').html('<div class="alert alert-warning">No se pudo cargar el perfil del estudiante.</div>');
                } else {
                    $('#perfilBody').html(html);
                }
                modalPerfil.show();
            },
            error: function (xhr) {
                var detail = xhr && (xhr.responseText || xhr.statusText) ? (xhr.responseText || xhr.statusText) : 'Error desconocido';
                $('#perfilBody').html('<div class="alert alert-danger">Error al cargar el perfil.<br/><small>' + $('<div/>').text(detail).html() + '</small></div>');
                modalPerfil.show();
            }
        });
    });

    $(document).on("click", ".btn-actualizar-estado", function () {
        var idUsuario = $(this).data("id");
        var estadoActual = $(this).data("estado");
        $("#hdnIdUsuario").val(idUsuario);
        $("#ddlNuevoEstado").val(estadoActual);
        $("#modalActualizarEstado").modal("show");
    });

    $("#btnConfirmarActualizar").click(function () {
        var idUsuario = $("#hdnIdUsuario").val();
        var nuevoEstado = $("#ddlNuevoEstado").val();

        $.ajax({
            url: CFG.urls.actualizarEstado,
            type: 'POST',
            data: { idUsuario: idUsuario, nuevoEstadoId: nuevoEstado },
            success: function (res, _status, xhr) {
                if (redirSiLogin(res, xhr)) return;
                if (res.success) {
                    $("#modalActualizarEstado").modal("hide");
                    tabla.ajax.reload();
                    Swal.fire("Éxito", res.message, "success");
                } else {
                    Swal.fire("Error", res.message, "error");
                }
            },
            error: function () {
                Swal.fire("Error", "Ocurrió un error al procesar la solicitud", "error");
            }
        });
    });

    $(document).on("click", ".btn-eliminar-doc", function (e) {
        e.preventDefault();
        var boton = $(this);
        var idDoc = boton.data("id");

        Swal.fire({
            title: '¿Eliminar documento?',
            text: "No podrás deshacer esta acción",
            icon: 'warning',
            showCancelButton: true,
            confirmButtonText: 'Sí, eliminar',
            cancelButtonText: 'Cancelar'
        }).then((result) => {
            if (result.isConfirmed) {
                $.ajax({
                    type: "POST",
                    url: CFG.urls.eliminarDocumento,
                    data: { id: idDoc },
                    success: function (res, _status, xhr) {
                        if (redirSiLogin(res, xhr)) return;
                        if (res.success) {
                            Swal.fire({
                                title: "Eliminado",
                                text: "Documento eliminado con éxito",
                                icon: "success",
                                timer: 1000,
                                showConfirmButton: false
                            });
                            boton.closest('.d-flex').fadeOut(300, function () { $(this).remove(); });
                        } else {
                            Swal.fire("Error", res.message || "No se pudo eliminar", "error");
                        }
                    },
                    error: function () {
                        Swal.fire("Error", "Ocurrió un error al procesar la solicitud", "error");
                    }
                });
            }
        });
    });

    $(document).on("click", ".BtnDesasignarPracticaEstudiante", function (e) {
        e.preventDefault();

        const boton = $(this);
        const idPractica = boton.data("idpractica");
        const idUsuario = boton.data("idusuario");

        const modalPerfil = bootstrap.Modal.getInstance(document.getElementById("modalPerfil"));

        if (modalPerfil && modalPerfil._focustrap) {
            modalPerfil._focustrap.deactivate();
        }

        Swal.fire({
            title: '¿Desea desasignar esta práctica?',
            text: 'El estado se cambiará a "Retirada".',
            icon: 'warning',
            input: 'textarea',
            inputLabel: 'Comentario (opcional)',
            inputPlaceholder: 'Escribe un comentario...',
            showCancelButton: true,
            confirmButtonText: 'Sí, desasignar',
            cancelButtonText: 'Cancelar',
            allowOutsideClick: false,
            didOpen: () => {
                const textarea = Swal.getInput();
                if (textarea) {
                    textarea.removeAttribute("readonly");
                    textarea.removeAttribute("disabled");
                    textarea.focus();
                    setTimeout(() => textarea.focus(), 100);
                }
            },
            didClose: () => {
                if (modalPerfil && modalPerfil._focustrap) {
                    modalPerfil._focustrap.activate();
                }
            }
        }).then((result) => {
            if (result.isConfirmed) {
                $.ajax({
                    url: CFG.urls.desasignarPractica,
                    type: 'POST',
                    data: {
                        idPractica: idPractica,
                        comentario: result.value || ''
                    },
                    success: function (res, status, xhr) {
                        if (redirSiLogin(res, xhr)) return;

                        if (res.ok) {
                            Swal.fire({
                                title: "Desasignado",
                                text: res.msg || "La práctica fue desasignada correctamente",
                                icon: "success",
                                timer: 1500,
                                showConfirmButton: false
                            }).then(() => {
                                $.ajax({
                                    url: CFG.urls.detalle,
                                    type: 'GET',
                                    data: { id: idUsuario },
                                    success: function (html) {
                                        if (html && html.trim() !== "") {
                                            $("#perfilBody").html(html);
                                        }
                                    }
                                });

                                if (typeof tabla !== "undefined") {
                                    tabla.ajax.reload(null, false);
                                }
                            });

                        } else {
                            Swal.fire("Error", res.msg || "No se pudo desasignar", "error");
                        }
                    },
                    error: function () {
                        Swal.fire("Error", "Ocurrió un error al procesar la solicitud", "error");
                    }
                });
            } else {
                if (modalPerfil && modalPerfil._focustrap) {
                    modalPerfil._focustrap.activate();
                }
            }
        });
    });

    $(document).ready(initTabla);

})();