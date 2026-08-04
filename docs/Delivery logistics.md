no debemos diseñar el sistema alrededor de “cada X segundos mando GPS”. Debemos diseñarlo alrededor de eventos + estado + sincronización, porque en una zona rural la conectividad es precisamente lo que no podemos dar por garantizado.

1. Principio fundamental

La aplicación tiene dos fuentes de verdad:

Servidor: verdad operacional y de negocio.

Teléfono: verdad temporal/local mientras está desconectado.

Cuando hay conexión:

Teléfono
   ⇅
Servidor

Cuando no hay conexión:

Teléfono
   │
   ├── GPS
   ├── estado del domicilio
   ├── eventos
   └── cola de sincronización

Y cuando vuelve la conexión:

Teléfono
   │
   │ eventos pendientes
   ▼
Servidor
   │
   ├── valida
   ├── ordena
   ├── resuelve conflictos
   └── confirma

La aplicación no debe depender de Internet para saber qué está haciendo el conductor en ese momento.

2. Estados del conductor

Yo utilizaría algo parecido a esto:

AVAILABLE
ASSIGNED
ON_ROUTE
AT_STOP
DELIVERING
COMPLETING
OFFLINE

Pero además tendríamos información independiente:

connectionStatus
gpsStatus
batteryStatus
lastServerContact
lastGpsPosition

Es decir, no metería todo dentro de un único DriverStatus.

Por ejemplo:

Driver
--------------------------------
status: ON_ROUTE

connection:
    ONLINE

GPS:
    AVAILABLE

battery:
    72%

lastHeartbeat:
    07:32:14

lastLocation:
    4.xxxxx, -74.xxxxx

Y otro conductor podría tener:

status: DELIVERING

connection:
    OFFLINE

GPS:
    AVAILABLE

battery:
    3%

lastHeartbeat:
    07:25:02

Eso nos cuenta una historia completamente diferente.

3. Estados del domicilio

Aquí sí quiero ser bastante estricto.

PENDING
ASSIGNED
ACCEPTED
EN_ROUTE
ARRIVED
DELIVERING
DELIVERED
FAILED
CANCELLED
REJECTED
REASSIGNING

Y las transiciones tienen reglas.

Por ejemplo:

PENDING
   ↓
ASSIGNED
   ↓
ACCEPTED
   ↓
EN_ROUTE
   ↓
ARRIVED
   ↓
DELIVERING
   ↓
DELIVERED

Pero también:

ASSIGNED
   ↓
REJECTED
   ↓
REASSIGNING

o:

EN_ROUTE
   ↓
FAILED
   ↓
REASSIGNING

dependiendo de la razón.

4. La batería

Tu idea de la batería debería formar parte explícita del sistema.

La aplicación puede enviar periódicamente:

batteryPercentage
batteryState
charging

Y generar eventos cuando cruza determinados umbrales.

Por ejemplo:

20% → LOW
10% → VERY_LOW
5%  → CRITICAL

No necesitamos estar enviando una actualización cada vez que cambia de 37 % a 36 %.

Es mejor detectar cambios relevantes.

Por ejemplo:

BATTERY_LOW
BATTERY_VERY_LOW
BATTERY_CRITICAL

Así podemos saber:

07:10
Battery = 18%

07:22
Battery = 9%

07:29
Battery = 4%
BATTERY_CRITICAL

07:31
Internet lost

Ahora tenemos una explicación bastante razonable de por qué desapareció el conductor.

5. Pero la batería no debe decidir sola

Esto es importantísimo.

No quiero una regla como:

“Batería < 5 % → reasignar.”

Eso sería peligroso.

La batería es una señal, no una decisión.

La decisión puede utilizar:

Tiempo offline
+
Última posición
+
Estado del domicilio
+
Batería
+
Última actividad
+
Si el pedido fue recogido
+
Prioridad

Por ejemplo:

Caso A
Offline: 6 minutos
Battery: 80%
GPS: activo
Domicilio: EN_ROUTE
Movimiento: sí

Probablemente:

NO reasignar.

Caso B
Offline: 8 minutos
Battery: 3%
GPS: última posición conocida
Domicilio: EN_ROUTE

Podríamos marcar:

REQUIERE ATENCIÓN

pero todavía no necesariamente reasignar.

Caso C
Offline: 20 minutos
Battery: 2%
Domicilio: ASSIGNED
Pedido todavía no recogido

Aquí sí:

REASIGNACIÓN AUTOMÁTICA, dependiendo de las reglas del negocio.

6. El GPS es independiente de Internet

Este punto es clave.

El teléfono puede tener:

GPS = YES
Internet = NO

Eso significa que podemos seguir obteniendo:

Latitud
Longitud
Timestamp
Precisión
Velocidad
Rumbo

Y almacenarlos localmente.

Por ejemplo:

LocationSample
----------------------
timestamp
latitude
longitude
accuracy
speed
heading

No necesariamente necesitamos guardar una posición cada segundo.

Podemos establecer reglas adaptativas.

Por ejemplo:

En movimiento:
cada 5-10 segundos

Detenido:
cada 30-60 segundos

Sin conexión:
guardar localmente

Con batería crítica:
reducir frecuencia

Eso ayuda muchísimo al consumo de batería.

7. La cola de eventos

Esta es probablemente una de las piezas más importantes de toda la aplicación.

El teléfono debería tener algo como:

LocalEventQueue

Y guardar eventos:

EVENT_ID
DRIVER_ID
ORDER_ID
EVENT_TYPE
TIMESTAMP
LATITUDE
LONGITUDE
DATA
SYNC_STATUS

Por ejemplo:

Event #A123
Driver: 42
Order: 881
Type: ARRIVED
Time: 07:31
GPS: ...
Sync: PENDING

El conductor puede estar sin Internet.

No importa.

La aplicación registra:

“Llegué al domicilio.”

Y continúa.

Cuando recupera Internet:

PENDING
   ↓
SYNCING
   ↓
ACKNOWLEDGED
8. Idempotencia

Aquí tenemos otro requisito que yo pondría explícitamente en la especificación para el agente de código.

Supongamos que el teléfono manda:

DELIVERED

El servidor lo recibe, pero se cae la conexión antes de enviar la confirmación.

El teléfono piensa:

“No sé si el servidor lo recibió.”

Entonces vuelve a enviar:

DELIVERED

El servidor debe poder decir:

“Este evento ya lo procesé.”

Y no crear una segunda entrega.

Por eso cada evento necesita un identificador único:

eventId = UUID

El backend debe procesar los eventos de forma idempotente.

9. ¿Qué ocurre si el conductor se queda sin batería?

Este escenario es diferente.

Supongamos:

07:25
Battery: 4%

07:26
Battery: 3%

07:27
Battery: 2%

07:28
PHONE OFF

El servidor recibe:

BATTERY_CRITICAL

pero después simplemente deja de recibir heartbeat.

El sistema puede inferir:

Probable battery shutdown

pero debemos distinguir entre:

hecho confirmado

y

inferencia del sistema.

Nunca deberíamos decir:

“El teléfono se apagó por batería.”

si realmente no lo sabemos.

Mejor:

lastKnownBattery = 2%
lastHeartbeat = 07:28
connectionLost = 07:28
possibleCause = LOW_BATTERY

Cuando el conductor vuelva:

DEVICE_RECONNECTED

y la aplicación sincroniza lo que tenga pendiente.

10. El caso complicado: pedido ya recogido

Aquí pondría una regla fuerte.

Si el conductor ya tiene físicamente el pedido, no podemos simplemente reasignarlo porque quedó offline.

Por ejemplo:

Order #500

Status:
DELIVERING

Driver:
42

Internet:
OFFLINE

Otro conductor no puede simplemente recibir:

“Ve a recoger el pedido 500.”

Porque el pedido está físicamente con el conductor 42.

Entonces necesitamos diferenciar:

Pedido no recogido

Puede ser relativamente fácil de reasignar.

Pedido recogido

Necesita un proceso diferente:

RECOVERY_REQUIRED

Y posiblemente intervención del operador.

Esto evita muchos problemas logísticos.

11. Cliente cancela mientras conductor está offline

Otro caso buenísimo.

Supongamos:

Cliente cancela
        ↓
Servidor
        ↓
Order = CANCELLED

Pero el conductor está offline.

Su teléfono todavía dice:

DELIVERING

Cuando vuelve la conexión, el servidor debe responder:

“El estado del pedido cambió mientras estabas desconectado.”

Y la aplicación debe sincronizar.

Esto es un conflicto de estado.

Por eso no podemos simplemente hacer:

Mobile state = Server state

sin más.

Necesitamos reglas de precedencia.

12. Una regla muy importante: los eventos son más útiles que los estados

En vez de guardar únicamente:

Order.Status = DELIVERED

también guardamos el historial:

ASSIGNED
07:10

ACCEPTED
07:11

EN_ROUTE
07:15

ARRIVED
07:29

DELIVERED
07:34

Esto nos da una auditoría completa.

Y permite responder preguntas como:

¿Quién tenía el domicilio?

¿Cuándo lo aceptó?

¿Dónde estaba?

¿Cuándo perdió conexión?

¿Cuánto tiempo estuvo offline?

¿Cuándo volvió?

¿Cuándo se entregó?

Eso para una aplicación logística es oro.

13. Reasignación

Yo crearía un servicio específico:

DispatchService

Su responsabilidad sería:

Detectar necesidad de reasignación
        ↓
Buscar candidatos
        ↓
Calcular puntuación
        ↓
Seleccionar conductor
        ↓
Bloquear pedido
        ↓
Asignar
        ↓
Notificar

La puntuación podría considerar:

Distance
ETA
Current workload
Driver availability
Zone
Vehicle capacity
Priority

Y posteriormente podemos incorporar:

Route impact
Traffic
Delivery windows
Historical performance
14. Algo todavía más importante: no hacer todo inmediatamente

Necesitamos un motor de políticas.

Por ejemplo:

IF driver offline
AND order = ASSIGNED
AND order not picked up
AND offline > 5 minutes
THEN candidate_for_reassignment

Pero:

IF driver offline
AND order = DELIVERING
AND order picked up
THEN do_not_auto_reassign

Y:

IF battery <= 5%
AND driver still moving
THEN warning

No necesariamente reasignación.

Esto hace que el comportamiento sea configurable.

15. Finalmente, el sistema debería tener tres capas

Yo documentaría el proyecto así:

┌──────────────────────────────────────┐
│         DRIVER MOBILE APP            │
│                                      │
│ GPS                                  │
│ Offline storage                      │
│ Event queue                          │
│ Battery monitoring                   │
│ Route display                        │
└──────────────────┬───────────────────┘
                   │
              HTTPS / SignalR
                   │
┌──────────────────▼───────────────────┐
│            BACKEND                   │
│                                      │
│ Order Service                        │
│ Driver Service                       │
│ Tracking Service                     │
│ Dispatch Engine                      │
│ Synchronization Service              │
│ Notification Service                 │
└──────────────────┬───────────────────┘
                   │
┌──────────────────▼───────────────────┐
│             DATABASE                 │
│                                      │
│ Drivers                              │
│ Orders                               │
│ Assignments                          │
│ Events                               │
│ Locations                            │
│ DeviceStatus                         │
│ AuditLog                             │
└──────────────────────────────────────┘

Y encima de todo esto pondríamos el proveedor de mapas, que podría ser Google Maps o Mapbox, pero manteniendo nuestra lógica de negocio independiente del proveedor.

Lo que yo haría ahora es convertir todo esto en una especificación formal, con:

Máquina de estados del conductor
Máquina de estados del domicilio
Máquina de estados de conexión
Máquina de estados de batería
Modelo de eventos
Reglas exactas de reasignación
Reglas de sincronización offline
Resolución de conflictos
Modelo de base de datos
Arquitectura ASP.NET Core + aplicación móvil
Integración con mapas
Los 12 escenarios de fallo, con comportamiento esperado
Casos de prueba que el agente de código debe implementar

Eso ya sería un documento que un agente de código podría utilizar como contrato de implementación, en lugar de tener que interpretar nuestra conversación.