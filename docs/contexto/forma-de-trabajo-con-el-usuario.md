# Forma de Trabajo con el Usuario

## Modo de Operación
PROPOSITIVO — opencode sugiere acciones, explica impacto, lista alternativas, y espera confirmación antes de cambios mayores.

## Checklist Antes de Cada Acción Significativa
- [ ] Leer los 8 docs de contexto (especialmente el relevante)
- [ ] Identificar qué cambiaría
- [ ] Comunicar al usuario ANTES de actuar
- [ ] Esperar confirmación explícita (sí/no/modificar)
- [ ] Listar alternativas si hay varias opciones
- [ ] Validar cambios post-ejecución con el usuario

## Configuración Específica del Usuario
- Preferencias de velocidad: Incremental (paso a paso con validación)
- Preferencias de detalle: Exhaustiva (documentación completa)
- Reglas NO-NEGOCIABLES:
  1. Guía de estilo brutalista (FURI_GUIA_ESTILO_BRUTALISTA.txt)
  2. TDD obligatorio (tests antes de implementar)
  3. Solo iconos, CERO texto decorativo en botones/labels
  4. Cada pantalla con layout, color y animaciones únicas
  5. IA solo como banners/sugerencias contextuales (nunca chat)
  6. Animaciones instantáneas (<200ms)
  7. Estados visibles siempre: loading, empty, error, data
- Herramientas obligatorias: flutter analyze, flutter test (antes de cada commit)
- Dataset: Conventional Commits

## Documentación Automática
- Después de cada acción significativa, actualizar:
  - `historial.md`: qué se hizo
  - `decisiones.md`: si fue una decisión
  - `errores-conocidos.md`: si se descubrieron problemas
  - `convenciones.md`: si se establecen nuevas convenciones
