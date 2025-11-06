# DeepRayCast3D Plugin

<img src="https://godotengine.org/asset-library/assets/logo_dark.svg" alt="Godot Icon" width="100"/>

## 📘 Descrição breve

O **DeepRayCast3D** é um poderoso **plugin para Godot Engine 4** que permite realizar **raycasts profundos**, atravessando múltiplos objetos em linha reta e registrando todas as colisões no caminho.  
Ideal para **sistemas de tiro**, **detecção de obstáculos**, **interação em cadeia**, **efeitos de laser**, entre outros.

---

## 🧩 Descrição completa

Diferente do `RayCast3D` padrão da Godot, o `DeepRayCast3D` é capaz de:

- Detectar **múltiplas colisões** ao longo de um único disparo de raio.
- **Ignorar objetos** específicos, incluindo o próprio pai ou nós definidos manualmente.
- Exibir uma **representação visual personalizável** (um feixe/cilindro 3D animado).
- Funcionar tanto em modo **automático (auto_forward)** quanto **manual (to)**.
- Emitir um **sinal com todas as colisões detectadas** durante o processo físico.

---

## ⚙️ Como funciona

O nó deve ser adicionado como **filho de um Node3D**.  
Ele pode emitir um raio continuamente durante `_physics_process`, detectando colisões e atualizando sua forma visual no editor e em tempo real durante o jogo.

---

## 🧱 Estrutura principal

```gdscript
@tool
@icon("res://addons/deep_raycast_3d/icon-16.png")
class_name DeepRayCast3D
extends Node
```

---

## 🚀 Propriedades do Inspetor

### 🟦 Process

| Propriedade   | Tipo    | Descrição                                               |
| ------------- | ------- | ------------------------------------------------------- |
| `enabled`     | `bool`  | Ativa ou desativa a verificação do raycast.             |
| `margin`      | `float` | Margem entre colisões consecutivas.                     |
| `max_results` | `int`   | Quantidade máxima de colisões que o raio pode detectar. |

### 🟨 Emission

| Propriedade         | Tipo    | Descrição                                          |
| ------------------- | ------- | -------------------------------------------------- |
| `activate_emission` | `bool`  | Ativa o brilho do raio.                            |
| `emission_energy`   | `float` | Intensidade da emissão luminosa.                   |
| `rings`             | `int`   | Número de anéis do cilindro que representa o raio. |
| `segments`          | `int`   | Número de segmentos laterais do cilindro.          |

### 🟩 Interaction

| Propriedade        | Tipo            | Descrição                                                             |
| ------------------ | --------------- | --------------------------------------------------------------------- |
| `auto_forward`     | `bool`          | Se verdadeiro, o raio aponta automaticamente para frente (-Z do pai). |
| `forward_distance` | `float`         | Distância do raio no modo automático.                                 |
| `to`               | `Node3D`        | Nó alvo (usado apenas se `auto_forward` for falso).                   |
| `exclude_parent`   | `bool`          | Ignora o nó pai nas colisões.                                         |
| `excludes`         | `Array[Node3D]` | Lista de nós a serem ignorados manualmente.                           |

### 🟪 Physics

| Propriedade           | Tipo   | Descrição                                        |
| --------------------- | ------ | ------------------------------------------------ |
| `collide_with_bodies` | `bool` | Detecta colisões com corpos.                     |
| `collide_with_areas`  | `bool` | Detecta colisões com áreas.                      |
| `hit_back_faces`      | `bool` | Detecta faces traseiras de malhas.               |
| `hit_from_inside`     | `bool` | Detecta colisões iniciando de dentro de shapes.  |
| `collision_mask`      | `int`  | Máscara de camadas de física a serem detectadas. |

### 🟥 Render

| Propriedade       | Tipo    | Descrição                       |
| ----------------- | ------- | ------------------------------- |
| `raycast_visible` | `bool`  | Exibe ou oculta o raio na cena. |
| `color`           | `Color` | Cor do feixe visual.            |
| `radius`          | `float` | Raio (espessura) do cilindro.   |
| `opacity`         | `float` | Opacidade do raio.              |
| `layers`          | `int`   | Camadas de renderização.        |

### ⚫ Transform

| Propriedade       | Tipo      | Descrição                          |
| ----------------- | --------- | ---------------------------------- |
| `position_offset` | `Vector3` | Offset de posição relativo ao pai. |

---

## 🔔 Signals

### `cast_collider(results: Array[DeepRaycast3DResult])`

Emitido toda vez que o raycast detecta uma ou mais colisões.  
O sinal retorna um array com todos os resultados, cada um do tipo `DeepRaycast3DResult`.

Exemplo:

```gdscript
func _ready():
    $DeepRayCast3D.cast_collider.connect(_on_cast_collider)

func _on_cast_collider(results: Array):
    for result in results:
        print("Colidiu com:", result.collider, "na posição:", result.position)
```

---

## 🧠 Métodos Públicos

| Método                     | Retorno         | Descrição                                    |
| -------------------------- | --------------- | -------------------------------------------- |
| `get_collider_count()`     | `int`           | Retorna o número de colisores detectados.    |
| `get_collider(index: int)` | `PhysicsBody3D` | Retorna o colisor do índice especificado.    |
| `get_normal(index: int)`   | `Vector3`       | Retorna a normal da colisão.                 |
| `get_position(index: int)` | `Vector3`       | Retorna a posição do ponto de colisão.       |
| `add_exclude(target)`      | `void`          | Adiciona um nó ou corpo à lista de exclusão. |
| `remove_exclude(target)`   | `void`          | Remove um nó ou corpo da lista de exclusão.  |

---

## 💡 Exemplos de uso

### 🔹 Acessando colisões manualmente

```gdscript
@onready var deep_ray = $DeepRayCast3D

func _physics_process(_delta):
    var count = deep_ray.get_collider_count()
    for i in range(count):
        var collider = deep_ray.get_collider(i)
        var position = deep_ray.get_position(i)
        var normal = deep_ray.get_normal(i)
        print("Colidiu com:", collider.name, "em", position, "normal:", normal)
```

### 🔹 Usando sinais

```gdscript
func _ready():
    $DeepRayCast3D.cast_collider.connect(_on_cast_collider)

func _on_cast_collider(results: Array):
    for r in results:
        print("Hit:", r.collider.name)
```

### 🔹 Adicionando exclusões

```gdscript
func _ready():
    var wall = get_node("Wall")
    $DeepRayCast3D.add_exclude(wall)
```

### 🔹 Removendo exclusões

```gdscript
func _input(event):
    if event.is_action_pressed("ui_accept"):
        var wall = get_node("Wall")
        $DeepRayCast3D.remove_exclude(wall)
```

---

## 🧰 Requisitos

- Godot Engine 4.0 ou superior
- Plugin instalado na pasta:  
  `res://addons/deep_raycast_3d/`

---

## 📦 Instalação

1. Copie a pasta `addons/deep_raycast_3d` para o seu projeto.
2. Ative o plugin em **Project → Project Settings → Plugins**.
3. Adicione um nó `DeepRayCast3D` como filho de um `Node3D`.

---

## 🧑‍💻 Autor

**Desenvolvido por Saulo**  
Plugin criado para expandir as capacidades de raycasting da Godot com precisão e controle profissional.

---

## 🏷️ Licença

Este projeto é licenciado sob a **MIT License**.  
Sinta-se livre para usar, modificar e distribuir.

## Screenshots

**Screenshot InputManager**

![Screenshot 1](./addons/input_manager/screenshots/all.png)
