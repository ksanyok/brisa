# Chromium для Brisa

Brisa использует отдельный экземпляр Chromium для выполнения браузерной автоматизации через DevTools Protocol. Чтобы облегчить скачивание и обновление стабильной версии, предоставляется данный каталог.

## Получение Chromium

1. Скачайте последнюю стабильную сборку Chromium для macOS с [официального сайта](https://commondatastorage.googleapis.com/chromium-browser-snapshots/index.html) или используйте `homebrew`:

   ```bash
   brew install --cask chromium
   ```

2. Скопируйте приложение `Chromium.app` в директорию `Tools/chromium-mac` или укажите путь к существующей версии в конфигурации Brisa.

3. При запуске Brisa создаст собственный профиль Chromium в `~/.brisa/chromium-profile` и не будет влиять на ваш основной браузер.

В будущем планируется автоматическая загрузка подходящей версии Chromium через скрипт.