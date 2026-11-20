# TaskFlow

**TaskFlow** — мобильное офлайн-приложение для управления проектами и задачами. Оно позволяет создавать задачи, распределять их между участниками, контролировать сроки и отслеживать изменения.

Данные хранятся локально в SQLite через Drift.

## Возможности

- Главная панель со сводной информацией.
- Создание, редактирование, поиск и удаление задач.
- Фильтрация задач по статусу, приоритету и исполнителю.
- Сортировка по сроку выполнения и дате создания.
- Поиск с debounce: запрос выполняется после паузы ввода 400 мс.
- Постраничная загрузка списка задач.
- Проекты, участники и роли.
- Комментарии, вложения и история изменений.
- Корзина с восстановлением и окончательным удалением.

## Архитектура

Проект постепенно переведён на Clean Architecture. Зависимости направлены от внешних слоёв к внутренним.

```text
lib/
├── core/
│   ├── di/                 # Централизованная регистрация зависимостей
│   └── error/              # Exceptions, Failures и ErrorMapper
├── database/               # SQLite / Drift
├── src/
│   ├── domain/
│   │   ├── entities/       # Бизнес-сущности
│   │   ├── repositories/   # Абстракции репозиториев
│   │   └── usecases/       # Отдельные бизнес-действия
│   ├── data/
│   │   ├── datasources/    # Локальный источник данных
│   │   ├── models/        # Модели хранения и преобразование в Entity
│   │   └── repositories/  # Реализации Domain Repository
│   └── presentation/
│       ├── providers/     # Состояние и контроллер списка задач
│       └── widgets/
├── data/                   # Совместимость с ещё не перенесёнными модулями
└── presentation/           # Экраны приложения
```

### Domain Layer

Содержит сущность TaskEntity, абстракцию TaskRepository и UseCases для просмотра, создания, изменения, удаления, переназначения, отмены статуса и восстановления задач. Domain не импортирует Flutter и Drift.

### Data Layer

TaskLocalDataSourceImpl работает с локальной базой Drift. TaskModel преобразуется в TaskEntity. TaskRepositoryImpl реализует доменный контракт и передаёт ошибки через ErrorMapper.

### Presentation Layer

Provider управляет TaskListController. Контроллер использует UseCases и предоставляет состояния initial, loading, success, empty и error. При ошибке список можно загрузить повторно.

### Dependency Injection

Все зависимости новой архитектуры регистрируются централизованно в `lib/core/di/injection.dart`. Старый репозиторий пока сохраняется для экранов и модулей, которые ещё не мигрировали.

### Обработка ошибок

ErrorMapper преобразует ошибки в типизированные Failure: NetworkFailure, ServerFailure, UnauthorizedFailure, ValidationFailure, DatabaseFailure и UnknownFailure. Пользовательский интерфейс получает безопасное сообщение вместо технического текста исключения.

## Технологии

- Flutter / Dart
- SQLite / Drift
- Provider
- build_runner

## Запуск

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Проверка качества

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

GitHub Actions автоматически выполняет генерацию Drift, статический анализ и тесты при push и pull request в main.

## Автор

**heoffy** — [GitHub](https://github.com/heoffy-st)
