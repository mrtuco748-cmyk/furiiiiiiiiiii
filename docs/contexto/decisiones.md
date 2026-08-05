# Decisiones de Arquitectura

### D-1: Provider como state management
- **Fecha**: 2026-07-29
- **Qué se decidió**: Usar Provider (ChangeNotifier) como solución de state management
- **Por qué**: Simple, nativo de Flutter, suficiente para 2 usuarios, evita overengineering con Bloc/Riverpod
- **Alternativas descartadas**: Bloc (mucho boilerplate), Riverpod (menos conocido), GetIt (muy mágico)
- **Impacto**: 11 providers en MultiProvider, patrón CRUD en cada uno
- **Revisable**: Sí — si el proyecto escala, migrar a Riverpod

### D-2: Supabase como backend único
- **Fecha**: 2026-07-29
- **Qué se decidió**: Supabase cloud como backend principal (DB, Realtime, Edge Functions)
- **Por qué**: Ofrece PostgreSQL + Realtime + Auth + Storage + Edge Functions en un solo servicio
- **Alternativas descartadas**: Firebase (más caro, menos SQL), Backend propio (mucho trabajo), PocketBase (menos maduro)
- **Impacto**: Toda la lógica de negocio en PostgreSQL + Edge Functions
- **Revisable**: Sí — si los costos escalan, considerar self-hosted

### D-3: SQLite como almacenamiento local
- **Fecha**: 2026-07-29
- **Qué se decidió**: SQLite para datos de calendario local (schedules, event_types, class_schedules)
- **Por qué**: El calendario necesita funcionar offline y tener baja latencia
- **Alternativas descartadas**: Solo Supabase (sin offline), Hive (menos relacional)
- **Impacto**: Dual persistence — algunos datos en SQLite, otros en Supabase
- **Revisable**: Sí — idealmente unificar a Supabase con sync offline robusto

### D-4: Unity con diseño brutalista
- **Fecha**: 2026-07-29
- **Qué se decidió**: Adoptar estética brutalista para toda la app: bordes rectos, colores vibrantes, alto contraste, sin adornos
- **Por qué**: Identidad visual única, diferenciación, apuesta estética fuerte
- **Alternativas descartadas**: Material Design 3 (genérico), Cupertino (solo iOS), diseño flat (soso)
- **Impacto**: Cada pantalla debe implementar la guía de estilo brutalista
- **Revisable**: No — es la identidad del proyecto

### D-5: Provider como state management en lugar de BLoC
- **Fecha**: 2026-07-29
- **Qué se decidió**: No se implementó BLoC a pesar de estar en planes anteriores
- **Por qué**: Provider es más simple y directo para el alcance actual
- **Alternativas descartadas**: BLoC (mucho código boilerplate), GetX (demasiado mágico y problemático)
- **Impacto**: Providers relativamente simples sin streams complejos
- **Revisable**: Sí

### D-6: Sin autenticación real (selector de identidad)
- **Fecha**: 2026-07-29
- **Qué se decidió**: Sistema de login basado en selección de identidad (Facu/Rocio) sin auth real
- **Por qué**: App privada para 2 usuarios, simplifica enormemente el desarrollo
- **Alternativas descartadas**: Supabase Auth, Firebase Auth, OAuth (overkill para 2 personas)
- **Impacto**: Sin seguridad real, cualquiera con acceso físico puede ver los datos
- **Revisable**: Sí — si se abre a más usuarios, implementar auth

### D-7: Firebase Cloud Messaging para push
- **Fecha**: 2026-07-29
- **Qué se decidió**: Usar FCM para notificaciones push con Supabase Edge Function como relay
- **Por qué**: FCM es el estándar para push en Android/iOS, Edge Function envía desde el servidor
- **Alternativas descartadas**: OneSignal (dependencia extra), solo notificaciones locales (sin push)
- **Impacto**: Dependencia de Firebase + Edge Function para push
- **Revisable**: Sí

### D-8: Gemini 1.5 Flash para IA
- **Fecha**: 2026-07-29
- **Qué se decidió**: Google Generative AI (Gemini 1.5 Flash) para funcionalidades de IA
- **Por qué**: Modelo rápido, económico, buena calidad para sugerencias contextuales
- **Alternativas descartadas**: OpenAI GPT (más caro), Claude (sin SDK Dart nativo), Ollama local (mucho setup)
- **Impacto**: API key hardcodeada (temporal), dependencia de internet para IA
- **Revisable**: Sí

### D-9: SyncProvider como event bus entre secciones
- **Fecha**: 2026-07-29
- **Qué se decidió**: Crear un SyncProvider central que actúa como bus de eventos para comunicación entre módulos
- **Por qué**: Evita dependencias directas entre providers (ej: al crear examen en calendario, avisar a estudio)
- **Alternativas descartadas**: Dependencias directas entre providers (acoplamiento), streams globales (menos control)
- **Impacto**: Arquitectura de eventos desacoplados con cola de reintentos
- **Revisable**: Sí

### D-10: Bot WhatsApp con Baileys + GitHub Actions (sin hosting propio)
- **Fecha**: 2026-08-05
- **Qué se decidió**: Crear bot de WhatsApp que notifica actividad de la app cada 30 min usando Node.js + Baileys, ejecutado en GitHub Actions (gratis)
- **Por qué**: Notificaciones push llegan solo al celu, pero no hay visibilidad proactiva de actividad en otras secciones. Baileys usa WhatsApp Web (sin API de Meta Business), GitHub Actions es gratis y no requiere servidor
- **Alternativas descartadas**: WhatsApp Cloud API de Meta (requiere numero de negocio verificado, costos), servidor 24/7 (costo mensual), solo Edge Functions (no pueden mantener conexion WebSocket para WhatsApp)
- **Impacto**: Nueva carpeta `bot-furi/`, 2 tablas Supabase nuevas (`bot_sessions`, `bot_notificaciones`), sesion WhatsApp persistida en BD, GitHub Actions cada 30 min
- **Limitacion**: No es tiempo real (polling cada 30 min). Para tiempo real se necesitaria servidor 24/7 + WhatsApp Cloud API
- **Revisable**: Sí — si se necesita tiempo real, migrar a Edge Function + WhatsApp Cloud API

### D-11: Rating dual por usuario + critica compartida en Favoritos
- **Fecha**: 2026-08-05
- **Qué se decidió**: Cada favorito se califica con estrellas de forma independiente por Facu (`rating_facu`) y por Rocio (`rating_rocio`), y existe una sola critica de texto compartida (`critica`). El rating se asigna por identidad (`AppState.identity`) en el provider (`setRating(id, identity, value)`).
- **Por qué**: La app es de pareja y ambos consumen los mismos favoritos; un unico rating pierde la subjetividad de cada uno. La critica compartida evita redundancia (acordamos texto) y fomenta edicion colaborativa.
- **Alternativas descartadas**: critica por usuario (Facu y Rocio con su texto propio, mas rico pero mas complejo; descartado por ahora), un solo rating promediado (pierdela opinion individual), solo estrellas sin texto.
- **Impacto**: Schema `favorites` con 3 campos nuevos y `subtitle`/`rating` eliminados. Migracion `supabase/migration_favorites_dual_rating.sql`. UI rediseñada con mini filas de rating F/R, modal de detalle con edicion de critica + calificacion de ambos. Cualquiera puede calificarle al otro (ambos pueden editar todo). Promedio disponible cuando ambos calificaron.
- **Revisable**: Sí — si en el futuro se quiere critica por usuario, agregar `critica_facu`/`critica_rocio` y migrar
