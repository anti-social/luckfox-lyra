# Luckfox Lyra BSP

Our changes on top of the Luckfox Lyra SDK (release v1.4, RK3506, Linux 6.1).
The SDK itself is not tracked here: this repo holds only patches for the SDK
projects, helper scripts, the build container and U-Boot env files.

```
patches/<project>/   patches for each SDK project (kernel-6.1, buildroot, device/rockchip)
                     and for the repo tool (.repo/repo, Python 3 support)
scripts/             apply-patches.sh / export-patches.sh, settings in common.sh
envs/                U-Boot environments, packed with ./build.sh env
custom-overlay/      rootfs overlay (git submodule)
Containerfile        Ubuntu 22.04 build environment
```

## Initialize

1. Download the [SDK archive](https://drive.google.com/file/d/15nq-Fac9q6zmisKZgLDZyoifSkL_48rG/view?usp=drive_link) (see `Google Drive` link on [Download](https://wiki.luckfox.com/Luckfox-Lyra/Download/#downloads) page for actual link)
   and unpack it next to this repo's files, i.e. into the directory you cloned:

   ```sh
   git clone <this repo> luckfox-lyra && cd luckfox-lyra
   tar -xzf /path/to/luckfox-lyra-<version>.tar.gz
   ```

2. Patch the bundled `repo` tool so it runs on Python 3:

   ```sh
   scripts/apply-patches.sh .repo/repo
   ```

3. Check out the SDK projects from the local `.repo/` (no network access needed):

   ```sh
   .repo/repo/repo sync -l
   ```

4. Apply our patches as commits on the `main` branch of each project:

   ```sh
   scripts/apply-patches.sh
   ```

## Build

The SDK builds only on Ubuntu 22.04, so use the container:

```sh
podman build -t lyra-sdk .
podman run --rm -it -v "$PWD:/work" -w /work lyra-sdk
```

Always build from the same path (`/work`): Buildroot stores absolute paths in
its output, so switching paths requires a clean rebuild.

Inside it:

```sh
# board: RK3506G_Luckfox_Lyra_Plus, boot medium: SPI_NAND, system: Buildroot
podman run --rm -it -v "$PWD:/work" -w /work lyra-sdk ./build.sh lunch

# build full image
podman run --rm -it -v "$PWD:/work" -w /work lyra-sdk ./build.sh

# env images from envs/*.txt -> output/env/
podman run --rm -it -v "$PWD:/work" -w /work lyra-sdk ./build.sh env
```

Images end up in `rockdev/` (`output/firmware`); `update.img` is the complete
firmware. Parts can be rebuilt with `./build.sh uboot|kernel|rootfs|firmware`.
See [SDK Image Compilation](https://wiki.luckfox.com/Luckfox-Lyra/SDK-Image-Compilation)
for details.

## Custom overlay

`custom-overlay/` is a git submodule that mirrors the target rootfs: e.g.
`custom-overlay/etc/foo.conf` is installed as `/etc/foo.conf`. It is copied
over the rootfs on every `./build.sh rootfs`. The SDK reaches it through the
`device/rockchip/common/overlays/rootfs/custom/root` symlink (added by our
`device/rockchip` patch); `overlay` in the SDK root links there too.

Fetch it after cloning:

```sh
git submodule update --init
```

## Userdata partition

SPI NAND has an 11.5MB UBI `userdata` partition (`/dev/mtd3`), mounted at
`/userdata` at boot. Put the files for it into `userdata/` in the SDK root (not
tracked here) and pack `output/firmware/userdata.img`:

```sh
podman run --rm -it -v "$PWD:/work" -w /work lyra-sdk ./build.sh extra-parts
```

Files that the rootfs build installs into `/userdata` also end up in the image.
To update it from the running board:

```sh
umount /userdata && ubidetach -p /dev/mtd3
ubiformat /dev/mtd3 -y -f userdata.img
reboot
```

## Working on changes

Commit in the SDK project as usual, then export and commit the patches here:

```sh
scripts/export-patches.sh
git add patches && git commit
```

After pulling someone else's changes, run `scripts/apply-patches.sh` again.
It resets each patched project's `main` to the SDK revision and replays the
patches; the previous state is kept in the `main-prev` branch.
