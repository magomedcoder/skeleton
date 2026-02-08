# Legion

---

## ⚠️ Предупреждение

**Проект на ранней стадии разработки.**

---

### Клиентское приложение

| Платформа | Версия                                |
|-----------|---------------------------------------|
| Linux     | glibc 2.31+ (Ubuntu 20.04+ и аналоги) |
| Android   | 7.0+                                  |
| iOS       | 13.0+                                 |
| macOS     | Catalina 10.15+                       |
| Windows   | 10+                                   |

---

### Серверная часть

- **Хост:** Linux (Debian, Ubuntu) или Docker
- **БД:** PostgreSQL 16
- **Раннеры:** видеокарты **NVIDIA** (экспериментально llama.cpp) или **Ollama** по API

---

## Разработка

### Зависимости

- **Go** 1.25+
- **PostgreSQL** 16+
- **Клиент (Flutter/Dart):**
    - Flutter 3.24+
    - Dart SDK ^3.10.7
- **Protobuf** 30.2+
- (Опционально) Ollama и llama.cpp и NVIDIA драйверы + CUDA для раннеров

Установка зависимостей клиента: `cd client-side && flutter pub get`.

Сервисы:

- **legion** - основной сервер (порт `50051`)
- **legion-runner** - раннер (порт `50052`)
- **postgres** - БД (порт `5432`)

### Сборка и тесты и запуск

#### Сборка

```bash
# Сборка сервера
make build
# Сборка раннера
make build-runner
# Или сборка раннера с поддержкой NVIDIA
make build-runner-nvidia
```

#### Тесты

```bash
# Тесты Go
make test
# Тесты Flutter
make client-test
```

#### Запуск

```bash
./build/legion
./build/legion-runner
```

### Или запуск без сборки

```bash
# Запуск сервера
make run
# Запуск раннера
make run-runner
# Запуск с поддержкой NVIDIA
make run-runner-nvidia
```

### Генерация кода из Protobuf

```bash
# Установка protoc плагинов
make install
# Генерация Go и Dart из api/proto/*.proto
make gen
```

### Скачивание исходников llama.cpp и Ollama

Клонирование репозиториев в `third_party/`, сборка библиотеки llama.cpp с CUDA и раннера:

```bash
# Клонирование llama.cpp и ollama в third_party/
make deps
# Сборка libllama.a с поддержкой NVIDIA
make build-llama-cublas
# Сборка legion-runner с тегом nvidia
make build-runner-nvidia
```

---

## Структура репозитория

| Каталог        | Описание                                |
|----------------|-----------------------------------------|
| `api/proto/`   | Protobuf-схемы                          |
| `cmd/legion/`  | Точка входа основного сервера           |
| `cmd/runner/`  | Точка входа сервиса-раннера             |
| `client-side/` | Flutter-клиент                          |
| `internal/`    | Домен, хендлеры, репозитории, раннер    |
| `migrations/`  | SQL-миграции PostgreSQL                 |
| `pkg/`         | Общие пакеты                            |
| `scripts/`     | Скрипты сборки (deb, Windows installer) |
