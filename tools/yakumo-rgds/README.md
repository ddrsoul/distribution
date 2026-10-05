# Yakumo (Monster Hunter Portable 3rd HD) для Anbernic RG DS

Порт [Yakumo](https://github.com/TeamGDB/Yakumo) — нативной (статически рекомпилированной)
версии Monster Hunter Portable 3rd HD Ver. — на RG DS под ROCKNIX.

- **Верхний экран 4:3 без чёрных полос.** Режим Fill с Vert+: по ширине видно столько же,
  сколько на PSP, а сверху и снизу больше. Интерфейс не растягивается.
  Только видеоролики 16:9 показываются с полосами.
- **Нижний экран — сенсорные кнопки Yakumo** (раскладка Action). Работают вместе со
  встроенным геймпадом и не прячутся при нажатии кнопок.

## Почему нужна сборка у себя

Yakumo собирается из исполняемого файла игры: рекомпилированный код получается из вашего
образа диска. Поэтому готового бинарника нет ни в образе ROCKNIX, ни здесь.
Его собирает скрипт на вашем ПК из **вашей** копии игры. Результат — для личного
использования, не распространяйте его.

Нужен образ `NPJB-40001` (Monster Hunter Portable 3rd HD Ver., несжатый `.iso`).
Подходят и фан-переводы, которые меняют только `DATA.BIN`.

## Сборка (Linux или WSL2, Docker)

Нужно около 8 ГБ ОЗУ и 15 ГБ места. Первая сборка занимает 1–2 часа.

```bash
cd tools/yakumo-rgds
docker build -t yakumo-rgds .
mkdir -p work out
docker run --rm \
  -v "$PWD/work:/work" -v "$PWD/out:/out" \
  -v /путь/к/MHP3rdHD.iso:/iso/game.iso:ro \
  yakumo-rgds /iso/game.iso
```

`work/` хранит исходники, сборки и ccache: повторная сборка идёт быстро.
`JOBS=N` (`-e JOBS=2`) ограничивает параллельность, если не хватает памяти.

Проверить, что всё компилируется, можно и без игры: `yakumo-rgds --no-game`.
Такая сборка не запускает игру.

## Установка на RG DS

1. Скопируйте `out/Yakumo.sh` и папку `out/yakumo/` в `/storage/roms/ports/` (раздел ROMS на SD).
2. Положите образ игры в `/storage/roms/ports/yakumo/` (любое имя, `.iso`).
   При первом запуске игра настроится из него сама. Без образа Yakumo откроет свою
   настройку и попросит выбрать файл.
3. Обновите список игр в EmulationStation и запустите **Yakumo** из раздела Ports.

Сохранения, настройки и логи лежат в `/storage/roms/ports/yakumo/data/`
(`ms0/PSP/SAVEDATA/ULJM05800` — сохранения в формате PSP, подходят сейвы с PSP/PPSSPP).

Меню Yakumo открывается по L3+R3. Пункты Video → Aspect ratio и Video → Narrow screens
переключают Fill и Vert+.

## Настройки лаунчера

Переменные окружения для `Yakumo.sh` (например, через `/storage/.config/profile.d/`):

| Переменная | По умолчанию | Назначение |
| --- | --- | --- |
| `YAKUMO_SINGLE_SCREEN=1` | выкл. | Только верхний экран, сенсорные кнопки поверх игры |
| `YAKUMO_TOP_OUTPUT` / `YAKUMO_BOTTOM_OUTPUT` | `DSI-2` / `DSI-1` | Выходы sway, как у DraStic |
| `YAKUMO_TOUCH_INPUT` | `1046:911:Goodix_Capacitive_TouchScreen` | Сенсор, привязываемый к нижнему экрану |
| `YAKUMO_VK_ICD` | драйвер из `gpudriver` | Другой Vulkan-драйвер (PanVK или libmali) |
| `YAKUMO_DATA_DIR` | `yakumo/data` | Где хранить данные |

## Что входит

| Файл | Назначение |
| --- | --- |
| `Dockerfile`, `aarch64-linux-gnu.cmake` | Debian 13 (glibc 2.41, как в ROCKNIX) с кросс-компилятором aarch64 |
| `build.sh` | Сборка: исходники Yakumo + патчи, хостовые инструменты, рекомпиляция, кросс-сборка, SDL3 только с Wayland |
| `patches/0001` | Vert+: настройка `video.vert_plus`, FOV камеры для экранов уже 480×272, тесты |
| `patches/0002` | `MHP3RD_SPLIT_SCREEN=640x480`: окно на два экрана, игра сверху, сенсорные кнопки снизу, меню только сверху |
| `patches/0003` | Кросс-сборка FFmpeg для Linux |
| `Yakumo.sh` | Лаунчер для Ports: раскладка экранов в sway, автонастройка из ISO |
| `settings.ini` | Настройки RG DS по умолчанию |

## Ограничения

- **Скорость не проверена.** RK3566 (4× Cortex-A55, Mali-G52) намного слабее устройств,
  на которых тестирует Yakumo. Если игра тормозит, попробуйте `video.internal_scale=1`.
- Нужен Vulkan 1.1. Если с одним драйвером не запускается, попробуйте другой через `YAKUMO_VK_ICD`.
- Привязка сенсора к нижнему экрану повторяет DraStic. Если касания попадают не туда,
  поменяйте `YAKUMO_TOUCH_INPUT` / `YAKUMO_BOTTOM_OUTPUT` и пришлите `data/yakumo.log`.
