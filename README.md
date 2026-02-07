# Engineering, Security & Architecture Rules (Rojo / Roblox Studio)

---

## General Principles
- **Understand first, code second**: siempre analizar y comprender completamente el sistema y su flujo antes de modificar o escribir código.
- **Roblox-first mindset**: este repositorio es una representación de Roblox Studio mediante **Rojo**. Programar pensando en la **jerarquía real de Instances**, no en paths tipo VS Code (`A/B`).
- Priorizar **claridad, mantenibilidad y seguridad** antes que complejidad innecesaria.
- Usar técnicas avanzadas **solo cuando aporten valor medible** (seguridad, performance, escalabilidad o mantenibilidad). Evitar overengineering.

---

## Architecture (OOP + Modular)
- Usar **OOP** para componentes con estado, ciclo de vida o responsabilidades claras (Services, Managers, Controllers).
- Usar módulos funcionales solo para **utilidades puras** (sin estado).
- Arquitectura **modular, autocontenida y escalable**:
  - Cada módulo principal debe encapsular sus scripts como **children**.
  - Exponer únicamente funcionalidad compartida a través de un folder **Public / Shared** dedicado.
  - Los scripts internos **NO** deben ser requeridos desde fuera del módulo.
  - Evitar acoplamientos entre módulos; comunicar mediante interfaces públicas.

---

## Module Lifecycle
- Cada módulo debe tener un **único punto de entrada** (`init.server.lua` / `init.client.lua`).
- Los módulos deben inicializarse **una sola vez**.
- No ejecutar lógica pesada durante `require`.
- La inicialización debe ser **explícita, ordenada e idempotente**.
- Un módulo debe ser seguro ante múltiples llamadas de inicialización.

---

## Project Structure & File Generation Rules

### Rojo Mapping
- La estructura del repositorio representa directamente Roblox Studio mediante **Rojo**.
- Cada folder del repositorio corresponde a un **Instance real** en Roblox Studio.
- Nunca pensar en rutas tipo filesystem; siempre pensar en el árbol real de Instances.

### Base Structure (Reference)
	src/
	├─ ServerScriptService/
	│  └─ Services/
	│     └─ /
	│        ├─ init.server.lua
	│        ├─ Public/
	│        └─ _Internal/
	│
	├─ ReplicatedStorage/
	│  └─ Shared/
	│
	├─ StarterPlayer/
	│  └─ StarterPlayerScripts/
	│     └─ Controllers/
	│        └─ /
	│           ├─ init.client.lua
	│           └─ _Internal/
	│
	└─ StarterGui/
	└─ UI/
	└─ /
	├─ init.client.lua
	└─ Components/

---

## File Generation Rules
- Nunca colocar lógica directamente en folders genéricos.
- Todo archivo debe pertenecer a un módulo claro.
- No crear archivos huérfanos.
- Un archivo debe tener **una sola responsabilidad clara**.
- Evitar archivos “god”.
- Convención de nombres:
  - `PascalCase` para módulos y clases.
  - `camelCase` para variables y métodos.

---

## Networking & Security (Anti-Exploit)
- **Server-authoritative siempre**.
- El servidor valida, decide y ejecuta.
- El cliente solo solicita y renderiza (UI / efectos).
- **Prohibido usar `RemoteEvent` o `RemoteFunction` directamente**.
- Usar exclusivamente el **módulo de networking del repositorio** (`Packets`, `Red`, etc.) siguiendo su formato.
- Validar **todas** las entradas del cliente:
  - tipos
  - rangos
  - ownership
  - estado actual
  - cooldowns
  - rate limits
- Diseñar handlers de red **idempotentes**, resistentes a spam y reintentos.

### Attributes
- Usar **Attributes** solo cuando sea **seguro y necesario**.
- El servidor es la única fuente de verdad.
- Nunca confiar en Attributes modificables por el cliente para decisiones autoritativas.

---

## Data Ownership Rules
- Cada pieza de estado debe tener **un solo owner claro**.
- El servidor es el único dueño del estado de juego.
- El cliente **nunca** muta estado autoritativo.
- No duplicar estado entre módulos.
- El acceso al estado debe hacerse únicamente mediante APIs públicas.

---

## Concurrency & Safety
- Asumir que el código puede ejecutarse concurrentemente.
- Evitar race conditions.
- No depender del orden de ejecución de eventos.
- No usar `task.wait()` como mecanismo de sincronización.
- El código debe ser **reentrancy-safe** y resistente a múltiples llamadas simultáneas.

---

## Performance & Complexity
- Evitar trabajo innecesario por frame.
- Evitar loops innecesarios.
- Preferir **O(1)** sobre O(n) cuando sea posible.
- Optimizar considerando:
  - Allocations
  - Garbage Collection
  - Replicación
  - Eventos y waits
- Cachear referencias y lookups costosos.
- Evitar `WaitForChild` dentro de loops o hot paths.
- Evitar usar XFunction(tabNode, { "txt", "text", "Title" }) para buscar elementos (Hazlo de forma mas eficiente cuando ya conoces el path.)

---

## Code Style & Practices
- Usar early returns cuando mejore la legibilidad:
  ```lua
  if condition then return end
    •   No usar print, warn, assert ni ningún tipo de logging a menos que se solicite 	    explícitamente.
	•	No agregar notas ni comentarios innecesarios.
	•	Evitar malas prácticas conocidas.
	•	El código debe verse humano, limpio y mantenible, evitando patrones repetitivos tipo “AI-smell”.

Typing
	•	Usar type annotations solo cuando aporten valor real:
	•	Interfaces públicas
	•	Estructuras complejas
	•	Evitar tipar todo el código por defecto.

⸻

Bug Finding & Fix Policy (IMPORTANTE)
	1.	Analizar todo el sistema relacionado.
	2.	Entender completamente el flujo y la intención original.
	3.	Identificar root causes, no solo síntomas.
	4.	Arreglar todos los bugs relacionados en una sola solución coherente.
	5.	Optimizar el código.
	6.	Reforzar seguridad y validaciones server-side.
	7.	Asegurarse de no romper comportamiento existente ni introducir nuevos bugs.

⸻

Tooling & Files
	•	Ignorar completamente los archivos .meta.json.
	•	No analizarlos.
	•	No crearlos.
	•	Asumir siempre sincronización con Roblox Studio vía Rojo.

⸻

Quality Bar
	•	Preferir soluciones simples, robustas y seguras.
	•	Usar técnicas avanzadas solo si aportan valor real y medible.
	•	Objetivo: software engineering de nivel senior, sin complejidad artificial.