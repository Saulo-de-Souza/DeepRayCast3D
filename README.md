# DeepRayCast3D — Advanced Multi-Collision Raycast for Godot 4.x

![Godot Icon](https://godotengine.org/themes/godotengine/assets/press/icon_color.png)

**DeepRayCast3D** is a powerful and flexible GDScript-based tool that extends the built-in `RayCast3D` capabilities.  
It allows a single ray to **pass through multiple colliders**, detecting all intersections along its path — perfect for visual effects, physics-based gameplay, or complex detection logic.

---

## 🌟 Features

- 🔁 **Multi-hit Raycasting** – detects all collisions along a ray, not just the first one.
- 🎯 **Dual Mode Targeting** – automatic forward direction or custom target node.
- 🧠 **Smart Exclusions** – ignore the parent or other specific objects easily.
- 💡 **Visual Debug Mesh** – configurable 3D ray visualization with emission and opacity.
- ⚙️ **Physics Layer Control** – selective collision detection using layer masks.
- 🧩 **Lightweight and Editor-Friendly** – updates in real-time in both editor and game mode.

---

## ⚙️ Installation

1. Copy the folder `addons/deep_raycast_3d/` into your Godot project.
2. In the **Project > Project Settings > Plugins** tab, enable **DeepRayCast3D**.
3. The node `DeepRayCast3D` will now appear in the "Add Node" dialog.

---

## 🧭 Usage

### Option 1 – Auto Forward Mode (default)

Automatically casts the ray in the forward direction of the **parent** node.

```gdscript
@onready var ray = $DeepRayCast3D

func _physics_process(delta):
    if ray._deep_results.size() > 0:
        for hit in ray._deep_results:
            print("Hit:", hit.collider, "at", hit.position)
```

### Option 2 – Manual Target Mode

Manually specify a `Node3D` target using the `to` property.

```gdscript
ray.auto_forward = false
ray.to = $Target
```

---

## 🧪 Exported Properties

| Category        | Property                     | Description                                             |
| --------------- | ---------------------------- | ------------------------------------------------------- |
| **Process**     | `enabled`                    | Enables or disables the raycast logic.                  |
|                 | `margin`                     | Minimum spacing between multiple hits.                  |
|                 | `max_results`                | Maximum number of detected collisions.                  |
| **Emission**    | `activate_emission`          | Enables ray emission effect.                            |
|                 | `emission_energy`            | Emission intensity.                                     |
|                 | `rings` / `segments`         | Ray mesh detail configuration.                          |
| **Interaction** | `auto_forward`               | Automatically cast forward based on parent orientation. |
|                 | `forward_distance`           | Length of the ray when in auto mode.                    |
|                 | `to`                         | Manual target node when auto mode is off.               |
|                 | `exclude_parent`             | Exclude parent node from detection.                     |
|                 | `excludes`                   | List of additional nodes to ignore.                     |
| **Physics**     | `collide_with_bodies`        | Detects physical bodies.                                |
|                 | `collide_with_areas`         | Detects areas.                                          |
|                 | `collision_mask`             | Collision layer bitmask.                                |
| **Render**      | `color`, `radius`, `opacity` | Visual style of the ray.                                |
|                 | `layers`                     | Rendering layer mask.                                   |

---

## 🧩 Signals

| Signal                                               | Description                                                |
| ---------------------------------------------------- | ---------------------------------------------------------- |
| `cast_collider(results: Array[DeepRaycast3DResult])` | Emitted every time the ray detects one or more collisions. |

---

## 🧱 Example Scene Setup

1. Add a `Node3D` as the parent.
2. Add `DeepRayCast3D` as a child node.
3. Adjust its parameters in the **Inspector** panel.
4. Connect the signal `cast_collider` to handle detected objects.

---

## 🧰 Integration Example

```gdscript
func _on_DeepRayCast3D_cast_collider(results):
    for res in results:
        print("Detected:", res.collider.name, "at position", res.position)
```

---

## 🧾 License

This plugin is distributed under the **MIT License**.  
You are free to use, modify, and distribute it in commercial and non-commercial projects.

---

## 👤 Author

Developed with ❤️ by **Saulo**  
Built for the **Godot 4.x** engine.

---

> “Precision meets flexibility — DeepRayCast3D helps you see every collision that matters.”

## Screenshots

**Screenshot InputManager**

![Screenshot 1](./addons/input_manager/screenshots/all.png)
