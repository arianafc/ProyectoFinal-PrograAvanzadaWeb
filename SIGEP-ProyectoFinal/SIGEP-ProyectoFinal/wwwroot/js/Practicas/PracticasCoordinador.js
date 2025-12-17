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
            'rezagado': 'badge-rezagado'
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
    $(document).on('click', '.btn-asignar', function () {
        const idUsuario = $(this).data('idusuario');

        if (!idUsuario) return;

        $('#modalAsignar').modal('show');
        recargarModalVacantes(idUsuario);
    });

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



});
