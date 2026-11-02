# BeedyOS

Дистрибутив на базе Arch Linux. Live-образ собирается через `archiso`, установка выполняется через `archinstall`.

## Для чего?

Главная идея собрать дистрибутив, который имеет в основном пакеты написанные на rust(в случае если это не вредит пользователю) 

Текущая версия содержит лишь набор пакетов для автоматической установки, однако планируется:

- Кастомные конфиги приложений
- Отдельный репозиторий для кастомных приложений/недоступных с AUR
- Переписанный инсталлер для экономии веса/чистоты проекта
- В разработке...

## Сборка

Требования:

- Arch Linux
- root
- пакеты `archiso`, `jq` (`base64` входит в `coreutils`)
- интернет: `pacstrap` скачивает пакеты

```bash
sudo pacman -S --needed archiso jq
sudo ./beedy/scripts/build.sh
```

Результат:

- `beedy/out/beedy-YYYY.MM.DD-x86_64.iso`
- `beedy/out/SHA256SUMS`

`build.sh` формирует список пакетов и конфиг archinstall, затем запускает:

```bash
mkarchiso -v -w work -o out profile
```

## Установка

1. Загрузиться с ISO.
2. Подключить сеть.
3. Запустить:

```bash
beedyinstall
```

`beedyinstall` проверяет доступ к `archlinux.org` и запускает:

```bash
archinstall --config /etc/beedy/archinstall.json
```

Параметры по умолчанию: GRUB, ядро `linux`, NetworkManager, `lemurs`, timezone `UTC`, swap через zstd, hostname `beedy`.

## Структура

```text
.
├── .gitattributes
├── .github/
│   ├── pull_request_template.md
│   └── workflows/ci.yml
├── .gitignore
├── .trufflehog-ignore
├── README.md
└── beedy/
    ├── README.md
    ├── archinstall/
    │   ├── base.json
    │   └── postinstall.sh
    ├── packages/
    │   ├── apps/packages.x86_64
    │   ├── base/packages.x86_64
    │   ├── desktop/packages.x86_64
    │   ├── dev/packages.x86_64
    │   ├── laptop/packages.x86_64
    │   ├── live/packages.x86_64
    │   ├── network/packages.x86_64
    │   └── system/packages.x86_64
    ├── scripts/
    │   └── build.sh
    └── profile/
        ├── profiledef.sh
        ├── pacman.conf
        ├── bootstrap_packages
        ├── packages.aarch64
        ├── efiboot/loader/
        │   ├── loader.conf
        │   └── entries/*.conf
        ├── grub/
        │   ├── grub.cfg
        │   └── loopback.cfg
        ├── syslinux/
        │   ├── syslinux.cfg
        │   ├── archiso_head.cfg
        │   ├── archiso_sys.cfg
        │   ├── archiso_sys-linux.cfg
        │   ├── archiso_pxe.cfg
        │   ├── archiso_pxe-linux.cfg
        │   ├── archiso_tail.cfg
        │   └── splash.png
        └── airootfs/
            ├── etc/
            │   ├── hostname
            │   ├── locale.conf
            │   ├── localtime -> /usr/share/zoneinfo/UTC
            │   ├── mkinitcpio.conf.d/archiso.conf
            │   ├── motd
            │   ├── os-release
            │   ├── pacman.d/hooks/*.hook
            │   ├── passwd
            │   ├── resolv.conf -> /run/systemd/resolve/stub-resolv.conf
            │   ├── shadow
            │   ├── ssh/sshd_config.d/10-archiso.conf
            │   └── systemd/...
            ├── root/
            │   ├── .automated_script.sh
            │   ├── .gnupg/scdaemon.conf
            │   └── .zlogin
            └── usr/local/
                ├── bin/
                │   ├── Installation_guide
                │   ├── beedyinstall
                │   ├── choose-mirror
                │   └── livecd-sound
                └── share/livecd-sound/asound.conf.in
```

## Техническая записка

- `beedy/profile` — профиль `archiso`: squashfs + xz, `install_dir="beedy"`, метка `BEEDY_YYYYMM`, режимы загрузки `bios.syslinux` и `uefi.systemd-boot`.
- `beedy/packages/*` — пакеты по группам. `build.sh` объединяет их в `profile/packages.x86_64`; группа `live` попадает только в live-образ.
- `beedy/archinstall/base.json` — базовая конфигурация archinstall. `build.sh` подставляет в неё список устанавливаемых пакетов (все группы, кроме `live`) и `custom_commands`.
- `beedy/archinstall/postinstall.sh` выполняется в chroot установленной системы: копирует `os-release` в `/usr/share/beedy`, настраивает `/etc/issue`, ставит pacman-hook для восстановления `os-release`, переименовывает записи systemd-boot, меняет `GRUB_DISTRIBUTOR` и пересобирает `grub.cfg`.
- `profile/airootfs` — live-окружение: автологин root на tty1, motd, сетевые конфиги, `beedyinstall`.
- `profile/packages.x86_64` и `profile/airootfs/etc/beedy/archinstall.json` генерируются `build.sh` и в git не хранятся.
- `beedy/work` и `beedy/out` — артефакты сборки, в git не хранятся.
- `.github/workflows/ci.yml` — TruffleHog secret scan.
- Live-ISO использует syslinux/systemd-boot. Установленная система использует GRUB через archinstall.
- `build.sh` собирает только x86_64; `profile/packages.aarch64` в текущей сборке не используется, поддержка не разрабывается.