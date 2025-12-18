$(function () {

    // === PREVENIR DOBLE CARGA ===
    if (window._PracticasScriptLoaded) return;
    window._PracticasScriptLoaded = true;

   


    // === BADGE DE ESTADO ===
    function badgeEstado(estadoOriginal) {
        const estado = (estadoOriginal || '')
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '')
            .toLowerCase()
            .trim();

        const mapa = {
            'asignada': 'badge-asignada',
            'aprobada': 'badge-aprobada',
            'en proceso de aplicacion': 'badge-en-progreso',
            'rechazada': 'badge-rechazada',
            'retirada': 'badge-retirada',
            'finalizada': 'badge-finalizada',
            'rezagado': 'badge-rezagado',
            'en curso': 'badge-en-curso'
        };

        const cls = mapa[estado] || 'badge-no-asignada';
        return `<span class="badge ${cls}">${estadoOriginal || '—'}</span>`;
    }

    $('.estado-postulacion').each(function () {
        const estado = $(this).data('estado');
        $(this).html(badgeEstado(estado));
    });

    // === INICIALIZAR DATATABLE (SIN AJAX) ===
    if ($.fn.dataTable.isDataTable('#miTabla')) {
        $('#miTabla').DataTable().destroy();
    }

    const table = $('#miTabla').DataTable({
        responsive: true,
        ordering: true,
        language: {
            url: "//cdn.datatables.net/plug-ins/1.13.6/i18n/es-ES.json"
        }
    });

    /* =============================
     * FILTRO POR ESTADO
     * ============================= */
    $('#filtroPractica').on('change', function () {
        var estado = $(this).val();
        table.column(4).search(estado).draw();
    });

    /* =============================
     * FILTRO POR ESPECIALIDAD
     * ============================= */
    $('#filtroEspecialidad').on('change', function () {
        var especialidad = $(this).find('option:selected').text();

        if (especialidad === "Todas") {
            table.column(2).search('').draw();
        } else {
            table.column(2).search(especialidad).draw();
        }
    });
    // === VER DETALLE POSTULACIÓN ===
    $(document).on('click', '.btn-ver', function () {
        const idVacante = $(this).data('idvacante');
        const idUsuario = $(this).data('idusuario');

        if (!idVacante || !idUsuario) {
            console.warn("⚠️ Faltan parámetros para ver detalle");
            return;
        }

        window.location.href =
            `/Practicas/VisualizacionPostulacion?idVacante=${idVacante}&idUsuario=${idUsuario}`;
    });

    // === ASIGNAR PRÁCTICA (abre modal) ===

    // === INICIAR PRÁCTICAS ===
    $('#btnIniciarPracticas').on('click', function () {
        Swal.fire({
            title: '¿Iniciar todas las prácticas?',
            html: `
            Las prácticas <b>Asignadas</b> pasarán a <b>En Curso</b>.<br>
            Las demás se marcarán como <b>Retirada</b>.
        `,
            icon: 'question',
            showCancelButton: true,
            confirmButtonText: 'Sí, iniciar',
            cancelButtonText: 'Cancelar',
            confirmButtonColor: '#2d594d'
        }).then(result => {
            if (result.isConfirmed) {
                ejecutarAccionPracticas(1);
            }
        });
    });


    // === FINALIZAR PRÁCTICAS ===
    $('#btnFinalizarPracticas').on('click', function () {
        Swal.fire({
            title: '¿Finalizar todas las prácticas?',
            html: `
            Las prácticas <b>Aprobadas</b> pasarán a <b>Finalizadas</b>.<br>
            Las demás se marcarán como <b>Rezagadas</b>.<br><br>
            Los estudiantes aprobados quedarán <b>Inactivos</b>.
        `,
            icon: 'warning',
            showCancelButton: true,
            confirmButtonText: 'Sí, finalizar',
            cancelButtonText: 'Cancelar',
            confirmButtonColor: '#768C46'
        }).then(result => {
            if (result.isConfirmed) {
                ejecutarAccionPracticas(2);
            }
        });
    });


    // === FUNCIÓN CENTRAL ===
    function ejecutarAccionPracticas(accion) {
        $.ajax({
            url: '/GestionPracticas/AccionarPracticas',
            type: 'POST',
            data: { accion },
            success: function (r) {
                Swal.fire({
                    title: r.success ? 'Proceso completado' : 'Error',
                    text: r.message,
                    icon: r.success ? 'success' : 'error',
                    confirmButtonText: 'Aceptar'
                }).then(() => {
                    if (r.success) {
                        location.reload(); 
                    }
                });
            },
            error: function () {
                Swal.fire('Error', 'No se pudo ejecutar la acción.', 'error');
            }
        });
    }

    ///LOGICA PARA TRAERME VACANTES DISPONIBLES///

    $(document).on('click', '.btn-asignar', function () {

        const idUsuario = $(this).data('idusuario');

        $('#modalAsignar').data('idusuario', idUsuario);

        cargarVacantes(idUsuario);

        const modal = new bootstrap.Modal(document.getElementById('modalAsignar'));
        modal.show();
    });

    function cargarVacantes(idUsuario) {

        $.ajax({
            url: '/GestionPracticas/ObtenerVacantesAsignar',
            type: 'GET',
            data: { IdUsuario: idUsuario },
            success: function (data) {

                const tbody = $('#miTablaAsignar tbody');
                tbody.empty();

                if (!data || data.length === 0) {
                    tbody.append(`
                    <tr class="text-center">
                        <td colspan="7">No hay vacantes disponibles</td>
                    </tr>
                `);
                    return;
                }

                data.forEach(v => {

                    let btnAsignar = `
                    <a href="javascript:void(0);" 
                       class="btn-confirmar-asignacion"
                       data-idvacante="${v.idVacante}"
                       style="color:#2d594d;">
                       <i class="fas fa-check-circle"></i>
                    </a>`;

                
                    if (v.estadoPractica === 'Finalizada') {
                        btnAsignar = '-';
                    }

                    tbody.append(`
                    <tr class="text-center">
                        <td>${v.nombreVacante}</td>
                        <td>${v.nombreEmpresa}</td>
                        <td>${v.especialidad}</td>
                        <td>${v.numCupos}</td>
                        <td>${v.cuposOcupados}</td>
                       
                        <td>${btnAsignar}</td>
                    </tr>
                `);
                });
            },
            error: function () {
                alert('Error al cargar vacantes');
            }
        });
    }

});
