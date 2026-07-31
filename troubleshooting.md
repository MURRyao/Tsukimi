# Tsukimi Troubleshooting

Документ группирует 16 проблем, найденных во время Swift/macOS code review.
Файл добавлен в `.gitignore` и предназначен как локальный рабочий чеклист.

## Capture And Screen Recording

1. Shelf может попасть в сам скриншот.
   `AppState.hideShelf()` сворачивает shelf в compact notch handle, но не скрывает окно полностью. Если пользователь снимает верхнюю часть экрана, UI Tsukimi может попасть в изображение. Нужно полностью прятать окна приложения на время capture или исключать их через `SCContentFilter`.

2. Нет защиты от повторного запуска capture.
   Повторное нажатие hotkey может создать несколько capture-задач. `OverlayRegionSelectionService.activeController` перезаписывается, что может оставить overlay windows или continuations в некорректном состоянии. Нужен single-flight guard, например `isCapturing`, или очередь capture-задач.

3. Fallback просит выбрать область второй раз.
   Native capture сначала просит выбрать регион, а при ошибке запускает `screencapture -i -s`, который снова запускает выбор области. Это выглядит как баг. Лучше выбирать backend до selection или научить fallback захватывать уже выбранный rectangle.

4. Конфликт hotkey блокирует показ notch handle на старте.
   `showNotchHandle()` вызывается после `registerHotKeys()`. Если один hotkey занят, приложение показывает ошибку, но UI может не появиться. UI нужно поднимать независимо, а ошибки hotkey показывать как recoverable state.

## Storage And Data Integrity

5. Поврежденный `manifest.json` ломает старт приложения.
   `ScreenshotRepository.load()` бросает ошибку, если manifest нельзя декодировать, а `AppState.start()` после этого не завершает startup. Лучше переименовывать битый manifest в backup, стартовать с пустым состоянием и показывать предупреждение.

6. Auto-cleanup работает только при старте.
   Expired unpinned screenshots остаются на диске, если приложение открыто долго. Нужен cleanup timer или запуск cleanup при capture, открытии shelf и изменениях settings.

7. Manifest не проверяет существование файлов.
   Если файл скриншота удален вручную, item остается в shelf, а drag/copy могут молча не работать. При `load()` стоит фильтровать missing files или помечать их как broken.

8. `Save As...` может удалить существующий файл пользователя до успешного copy.
   Код сначала удаляет destination, затем копирует screenshot. Если copy падает, старый файл уже потерян. Нужно использовать temporary file + atomic replace или `FileManager.replaceItemAt`.

## Shelf UI And User Experience

9. Действия карточек молча игнорируют ошибки repository.
   Delete, pin и drag-state updates используют `try?`, поэтому ошибки сохранения manifest или файловой системы скрываются. Эти действия лучше вести через `AppState` и показывать пользователю ошибку.

10. Thumbnail и drag data грузятся синхронно на UI path.
    `NSImage(contentsOf:)`, `Data(contentsOf:)` и TIFF generation могут фризить UI на больших скриншотах или длинном shelf. Нужны thumbnail cache и lazy `NSItemProvider` representations.

11. Drop target выглядит активным, но всегда отклоняет drop.
    Compact island принимает `.fileURL` и `.image`, меняет состояние на drag target, но handler возвращает `false`. Нужно либо реализовать import, либо убрать drop affordance.

12. В проекте есть неиспользуемый дублирующий window controller.
    `ShelfWindowController` остается в проекте, хотя `AppState` использует `NotchHostWindowController`. Это создает риск правок в неактивном коде. Лучше удалить его или явно пометить как deprecated.

## Settings And Preferences

13. Изменение storage settings не применяется к существующим item'ам.
    Изменение lifetime или max unpinned count влияет только на будущие скриншоты. Старые `expiresAt` не пересчитываются, overflow cleanup не запускается. Нужно наблюдать settings changes и пере применять repository policies.

## Project Configuration And Distribution

14. Deployment target выставлен в macOS `26.5`.
    Это сильно ограничивает совместимость. Нужно осознанно выбрать минимальную поддерживаемую macOS-версию и закрыть новые API через availability checks.

15. App Sandbox выключен.
    Приложение работает с приватными скриншотами, но `ENABLE_APP_SANDBOX = NO`. Это повышает security и distribution risk. Перед packaging/release стоит пересмотреть sandboxing и нужные entitlements.

## Testing Gaps

16. UI-тесты фактически отсутствуют.
    UI test files явно пропускают launch/UI tests. Unit tests покрывают часть storage и metadata behavior, но не самые рискованные потоки: capture overlay, shelf window behavior, permissions, global hotkeys и drag-and-drop. Нужен custom integration harness для menu-bar utility.
