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

### D-12: Media del chat con delete-on-download
- **Fecha**: 2026-08-05
- **Qué se decidió**: Los adjuntos del chat se suben a Supabase Storage (`chat-media`). Al descargarlos el receptor, se guardan solo en el dispositivo (SQLite `chat_media_local` + app docs) y se borran del bucket; el mensaje queda con `cloud_deleted=true` y sin `attachment_url`.
- **Por qué**: Privacidad/espacio — el media no vive en la nube indefinidamente; solo hace falta el puente de entrega.
- **Alternativas descartadas**: base64 en columna (pesado, ya usado en gallery), URLs publicas permanentes, sync bidireccional offline completo.
- **Impacto**: Flujo upload/download en `ChatMediaService` + `ChatProvider.downloadMedia`. Requiere ejecutar `supabase/migration_chat_media_reactions.sql`.
- **Revisable**: Sí — si se necesita reenviar media viejo, habria que no borrar o re-subir desde local del emisor.

### D-11: Rating dual por usuario + critica compartida en Favoritos
- **Fecha**: 2026-08-05
- **Qué se decidió**: Cada favorito se califica con estrellas de forma independiente por Facu (`rating_facu`) y por Rocio (`rating_rocio`), y existe una sola critica de texto compartida (`critica`). El rating se asigna por identidad (`AppState.identity`) en el provider (`setRating(id, identity, value)`).
- **Por qué**: La app es de pareja y ambos consumen los mismos favoritos; un unico rating pierde la subjetividad de cada uno. La critica compartida evita redundancia (acordamos texto) y fomenta edicion colaborativa.
- **Alternativas descartadas**: critica por usuario (Facu y Rocio con su texto propio, mas rico pero mas complejo; descartado por ahora), un solo rating promediado (pierdela opinion individual), solo estrellas sin texto.
- **Impacto**: Schema `favorites` con 3 campos nuevos y `subtitle`/`rating` eliminados. Migracion `supabase/migration_favorites_dual_rating.sql`. UI rediseñada con mini filas de rating F/R, modal de detalle con edicion de critica + calificacion de ambos. Cualquiera puede calificarle al otro (ambos pueden editar todo). Promedio disponible cuando ambos calificaron.
- **Revisable**: Sí — si en el futuro se quiere critica por usuario, agregar `critica_facu`/`critica_rocio` y migrar

### D-13: Merge atómico de reacciones en Postgres (RPC server-side, Fase 0)
- **Fecha**: 2026-08-26
- **Qué se decidió**: Las escrituras de reacciones dejan de enviar el mapa `reactions` completo y pasan a llamar a **2 RPC de Postgres** que hacen el merge DENTRO del servidor con row-level lock (`SELECT ... FOR UPDATE`): `toggle_reaction` (forma `{key:[uid]}`, cubre `messages.reactions`, `gallery.reactions`, `workout_*.social` y `board_elements_v2.data`, con whitelist estricta de tablas/columnas y max 5 keys) y `react_deck_card` (forma `{uid:emoji}` del mazo). Los providers hacen optimistic en memoria + reconciliación con la respuesta autoritativa de la RPC.
- **Por qué**: El update con mapa completo causaba race de "último write gana": dos reacciones simultáneas (Facu + Rocio) al mismo ítem se pisaban (BUG 2 CRÍTICO de la auditoría del pizarrón). El merge client-side en realtime era un parche; la RPC es la defensa real en el origen y garantiza consistencia en el servidor.
- **Alternativas descartadas**: mantener solo el merge client-side en realtime (no garantiza consistencia en el origen), triggers SQL por tabla (más tablas a mantener, no devuelve el estado para reconciliar), lock por UPDATE con retry en cliente (complejo y frágil).
- **Impacto**: 2 RPC + GRANT (`supabase/migration_reaction_rpc.sql`, **pendiente ejecutar en SQL Editor**), 5 providers rewireados (chat, gallery, workout, board, deck), método dedicado `BoardProviderV2.react()` (evita el push de documento completo), test-contrato en lógica pura. Suite 218 verdes.
- **Revisable**: Sí — la RPC con whitelist limita las tablas a las conocidas; si se agrega una tabla de reacciones nueva, hay que sumarla a la whitelist. Si se quiere migrar la feature entera a RLS + auth real, revisar.

### D-14: GoRouter (Navigator 2.0) como navegación centralizada
- **Fecha**: 2026-08-26
- **Qué se decidió**: Adoptar **GoRouter** con route table centralizado (`lib/router.dart`) y `MaterialApp.router`. ~30 sitios de `Navigator.push(MaterialPageRoute)` pasaron a `context.push`/`context.go` por `RouterRoutes`. El arranque login/home se resuelve con `redirect` basado en sesión (no `home:`).
- **Por qué**: Elimina el "push/pop chamuyado" disperso (convención prohibida), da un único lugar para declarar rutas, habilita `pushAndRemoveUntil`/`pushReplacement` como `go` y testing de navegación.
- **Alternativas descartadas**: mantener `Navigator` crudo (sin centralizar, contradice convenciones), un mini-router propio (reinventa la rueda). El enfoque híbrido (GoRouter solo para full-screens + Navigator para flujos con retorno) se descartó por mezcla sucia: `context.push<T>` ya propaga el `pop`, así no hace falta.
- **Impacto**: `go_router ^17.5.0`, `lib/router.dart` (22 rutas + `RouterRoutes` + `navigatorKey`), `main.dart` con `MaterialApp.router`, 8 screens rewired. Los objetos tipados (AppMode, Schedule, DateTime) viajan por `state.extra`. Flujo especial: `context.push<bool>` para el wizard de clases.
- **Nota Flutter 3.44**: `routerConfig` solo existe en **`MaterialApp.router`**; el constructor base ya NO lo acepta (por eso el error `undefined_named_parameter` intermitente engañaba — el analyzer lo cacheaba).
- **Revisable**: Sí — si la app gana deep-links/auth, migrar el `redirect` a autenticación real; si se agregan pantallas, sumarlas a `RouterRoutes` + tabla.
