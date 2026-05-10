# Steadfast for Shader Developers

I have attempted to bring together some information that will be helpful to you
if you want to modify or improve Steadfast. I cannot pretend that what is here
is comprehensive, but hopefully it is a useful start.

## Resources

- [Iris Documentation](https://shaders.properties)
- [Iris Source Code](https://github.com/IrisShaders/Iris)
- [ShaderLabs Wiki](https://shaderlabs.org/wiki/Main_Page)

## Design

Steadfast relies on forward-rendering for performance and correctness. Most of
the world rendering dispatches from 4 general shader programs:

* `lit` supports any object that receives normal lighting, since almost all
  lighting and graphics calculations are the same between blocks, entities, and
  other game objects. The "lit" shader supports opaque objects, "cutout" objects
  such as leaves, and even translucent objects that can reflect and refract.
* `unlit` supports special effects, emissive objects, and other unusual objects
  that do not receive normal lighting. For example, enchantment glints and block
  breaking effects.
* `sky` renders the atmosphere and planar clouds.
* `clouds` renders Minecraft's blocky clouds, when enabled.

Individual shader types that want to use a general shader program configure the
general program with preprocessor directives, such as `NEVER_RECEIVES_SHADOWS`.

The post-processing shaders and shadow-map have an absolute minimal amount of
logic in them as a result of the forward-rendering design, and because Steadfast
has very few post-processing effects because it dedicates nearly all of the
rendering performance budget to lighting, water, and atmosphere effects.

### How Steadfast gets good performance out of GPUs, especially mobile hardware

In general, Steadfast tries very hard to minimize memory requirements, as while
graphics hardware is generally constrained in both compute and memory, memory is
almost always the bottleneck. In the graphics programming community, a response
of "YOU'RE PROBABLY MEMORY BOUND" is a common answer to any performance issue.

* The memory buffer for sending attributes data from the vertex shader to the
  fragment shader is very small, and interpolating attribute data within a
  triangle is also very expensive. While you can sometimes remove interpolation
  with a `flat` attribute, generally you should never execute shading logic in
  a vertex shader unless it reduces the size of the vertex-to-fragment attribute
  data OR is strictly required (such as computing the vertex position).
* Shaders support passing in "uniform" data that remains the same across all
  geometry being rendered, meaning that it only needs to be calculated once on
  the CPU instead of across millions of shader invocations on the GPU. Reading
  uniform data has a small cost (it is a memory access, after all), so if you
  already read a uniform X, it doesn't make sense to have a separate uniform Y
  that is just X + 1 since running X + 1 in the shader will be faster, but there
  are many calculations that are more expensive than the memory read and which
  benefit greatly from being hoisted out of the shader. Steadfast uses uniforms
  extremely heavily for some very substantial performance improvements: lighting
  colors, fog colors, and similar calculations all happen in uniforms.
* Reading and writing to textures / images costs memory and is not cheap.
  This is why Steadfast uses forward rendering: deferred renderers have to write
  out and read a lot of data each frame, which can cost more performance than
  you save by lowering the number of lighting calculations, especially for the
  trivial lighting calculations Steadfast uses.
* However, reading textures is not THAT expensive, so if you can replace tens to
  hundreds of instructions with a single texture fetch, that will be faster!
* Otherwise, counting instructions and spotting cases where you can apply math
  identities, approximations, and similar techniques takes you the rest of the
  way. In shader packs, micro-optimization for a few percent more frames can be
  the difference between missing a few frames every now and then from vsync
  versus hitting a smooth 60 FPS!

## Code style

I have started to adopt a few rules when writing Steadfast since they seemed to
be useful. I will continue to extend and revisit these in the future.

* Hard line length limit of 80 characters with RARE exceptions.
	* This is for both readability reasons as it helps guide you to split up
	  long calculations into variables and multiple lines, but is also for
	  practicality, since it means you can fit a bunch of editor panes side by
	  side. Even on a laptop, this comfortably gives you two editor panes and a
	  sidebar in VSCode for example.
	* TODO: This is a problem for URLs and shader options, I am considering
	  making an exception for those.
* Tabs for indentation, spaces for alignment
	* https://dmitryfrank.com/articles/indent_with_tabs_align_with_spaces
* PascalCase function names for "exported" functions meant to be used outside
  of the file, camelCase for "private" functions.
	* TODO: Not everything complies with this perfectly, yet.

## Security (be careful with mods!)

You should run any form of modded Minecraft in a sandboxed environment to avoid
[malware](https://github.com/trigram-mrp/fractureiser) and supply-chain attacks.
There is no simple solution for this on Windows or macOS, but on Linux the
[Prism Launcher](https://flathub.org/en/apps/org.prismlauncher.PrismLauncher)
Flatpak app makes this trivial, and I can highly recommend this solution.

Malware in Minecraft mods is fortunately not common, and there are no instances
of supply-chain attacks having yet impacted core mods like Fabric, Sodium, and
Iris, but with how easy Flatpak is to use, running modded Minecraft outside of
a sandbox is franky irresponsible.

### How to maintain isolation between your development environment and the game

When running Minecraft in a sandboxed environment, it is important to maintain a
d evelopment environment outside of the Minecraft game folder. You can create
the following script a name like `sync.sh` in this folder for this purpose:

```shell
#!/bin/sh

LAUNCHER_INSTALL=~/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher
INSTANCE="Steadfast Shader Development"
SHADERPACKS="$LAUNCHER_INSTALL/instances/$INSTANCE/.minecraft/shaderpacks"
SHADERS="$SHADERPACKS/Steadfast/shaders/"

./build.sh && rm -rf "$SHADERS" && cp -pr shaders/ "$SHADERS"
```

In particular, this is important when running the game in a Flatpak container
while using Git version control on the host system. If we placed the Git folder
within the container, the container could trivially compromise the host by
writing a malicious hook to the Git folder, which would be executed the next
time we ran a Git command.
