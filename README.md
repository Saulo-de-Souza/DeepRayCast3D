# DeepRayCast3D — Advanced Multi-Collision Raycast for Godot 4.x

<img src="https://godotengine.org/asset-library/assets/logo_dark.svg" alt="Godot Icon" width="100"/>

**DeepRayCast3D** is a powerful and flexible GDScript-based tool that extends the built-in `RayCast3D` capabilities.  
It allows a single ray to **pass through multiple colliders**, detecting all intersections along its path — perfect for visual effects, physics-based gameplay, or complex detection logic.

---

## Features

- **Multi-hit Raycasting** – detects all collisions along a ray, not just the first one.
- **Dual Mode Targeting** – automatic forward direction or custom target node.
- **Smart Exclusions** – ignore the parent or other specific objects easily.
- **Visual Debug Mesh** – configurable 3D ray visualization with emission and opacity.
- **Physics Layer Control** – selective collision detection using layer masks.
- **Lightweight and Editor-Friendly** – updates in real-time in both editor and game mode.

---

## Installation

1. Copy the folder `addons/deep_raycast_3d/` into your Godot project.
2. In the **Project > Project Settings > Plugins** tab, enable **DeepRayCast3D**.
3. The node `DeepRayCast3D` will now appear in the "Add Node" dialog.

---

## Usage

### Option 1 – Auto Forward Mode (default)

Automatically casts the ray in the forward direction of the **parent** node.

```gdscript
@onready var deep_ray_cast_3d: DeepRayCast3D = $Player/DeepRayCast3D

func _physics_process(_delta):
	if deep_ray_cast_3d.get_collider_count() > 0:
		for i in range(deep_ray_cast_3d.get_collider_count()):
			var collider = deep_ray_cast_3d.get_collider(i)
			var normal = deep_ray_cast_3d.get_normal(i)
			var pos = deep_ray_cast_3d.get_position(i)
			print("Collider: ", collider, " Normal: ", normal, " Position: ", pos)
```

### Option 2 – Manual Target Mode

Manually specify a `Node3D` target using the `to` property.

```gdscript
ray.auto_forward = false
ray.to = $Target
```

---

## Exported Properties

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

## Signals

| Signal                                               | Description                                                |
| ---------------------------------------------------- | ---------------------------------------------------------- |
| `cast_collider(results: Array[DeepRaycast3DResult])` | Emitted every time the ray detects one or more collisions. |

---

## Example Scene Setup

1. Add a `Node3D` as the parent.
2. Add `DeepRayCast3D` as a child node.
3. Adjust its parameters in the **Inspector** panel.
4. Connect the signal `cast_collider` to handle detected objects.

---

## Integration Example

```gdscript
func _on_DeepRayCast3D_cast_collider(results):
    for res in results:
        print("Detected:", res.collider.name, "at position", res.position)
```

---

## Screenshots

**Screenshot InputManager**

![Screenshot 1](./addons/input_manager/screenshots/all.png)
