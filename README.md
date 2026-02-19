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
- **Кэш и очереди:** Redis 7+
- **MinIO** - S3-совместимое хранилище медиа
- **Раннеры:** видеокарты **NVIDIA** (экспериментально llama.cpp) или **Ollama** по API

---

## Разработка

### Зависимости

- **Go** 1.25+
- **PostgreSQL** 16+
- **Redis** 7+
- **MinIO**
- **Клиент (Flutter/Dart):**
    - Flutter 3.24+
    - Dart SDK ^3.10.7
- **Protobuf** 30.2+
- (Опционально) Ollama и llama.cpp и NVIDIA драйверы + CUDA для раннеров

Установка зависимостей клиента: `cd client-side && flutter pub get`.

---

### Конфигурация

### Основной сервер (legion)

Конфигурация загружается из файла, заданного переменной окружения **`LEGION_CONFIG`**.
По умолчанию: `./configs/config.yaml`.

**Параметры:**

- `server` - `host`, `port` (адрес и порт сервера, по умолчанию `0.0.0.0:50051`)
- `postgres` - `host`, `port`, `username`, `password`, `database` (подключение к PostgreSQL)
- `redis` - `host`, `port`, `auth`, `database` (подключение к Redis для кэша и pub/sub)
- `jwt` - `access_secret`, `refresh_secret`, `access_ttl`, `refresh_ttl` (секреты и время жизни токенов)
- `runners` - `registration_token`, `addresses` (токен регистрации и список адресов раннеров)
- `minio` - `host`, `port`, `ssl`, `secret_id`, `secret_key`, `bucket` (S3-совместимое хранилище медиа)
- `log` - `level` (уровень логирования: `debug`, `verbose`, `info`, `warn`, `error`, `off`)

### Раннер (legion-runner)

Конфигурация загружается из файла, заданного переменной окружения **`LEGION_RUNNER_CONFIG`**.
По умолчанию: `./configs/runner-config.yaml`.

**Параметры:**

- `core_addr` - адрес основного сервера для регистрации (по умолчанию `127.0.0.1:50051`)
- `listen_addr` - адрес для приёма gRPC-запросов (по умолчанию `127.0.0.1:50052`)
- `registration_token` - токен для регистрации на сервере
- `log` - `level` (уровень логирования: `debug`, `verbose`, `info`, `warn`, `error`, `off`)
- `engine` - движок: `"ollama"` или `"llama"`
- `ollama` - `base_url` (URL API Ollama, по умолчанию `http://127.0.0.1:11434`)
- `llama` - `model_path` (каталог с моделями для llama.cpp)

---

### Сборка, тесты и запуск

#### Сборка

```bash
# Сборка сервера
make build
# Сборка раннера (Ollama / без GPU)
make build-runner
# Сборка раннера с поддержкой NVIDIA (llama.cpp + CUDA)
make build-runner-nvidia
```

#### Запуск без сборки

```bash
# Запуск сервера
make run
# Запуск раннера (с тегом nvidia)
make run-runner
# Запуск раннера (с движком llama.cpp)
make run-runner-llama
```

### Генерация кода из Protobuf

```bash
# Установка protoc плагинов
make install
# Генерация Go и Dart из api/proto/*.proto
make gen
```

### Скачивание исходников llama.cpp и Ollama

Клонирование репозиториев в `third_party/`, сборка библиотеки llama.cpp:

```bash
# Клонирование llama.cpp и ollama в third_party/
make deps
# Сборка libllama.a (без CUDA)
make build-llama
# Сборка libllama.a с поддержкой NVIDIA (CUDA)
make build-llama-cublas
# Сборка legion-runner с тегом nvidia
make build-runner-nvidia
```

---

#### Тесты

```bash
# Тесты Go
make test
# Тесты Flutter
make client-test
# Нагрузочные тесты
make test-load
```

---

## Структура репозитория

| Каталог        | Описание                                                                                  |
|----------------|-------------------------------------------------------------------------------------------|
| `api/proto/`   | Protobuf-схемы                                                                            |
| `api/pb/`      | Сгенерированный Go-код из proto (после `make gen`)                                        |
| `cmd/legion/`  | Точка входа основного сервера                                                             |
| `cmd/runner/`  | Точка входа сервиса-раннера                                                               |
| `client-side/` | Flutter-клиент                                                                            |
| `configs/`     | YAML-шаблоны конфигурации (config.template.yaml, runner-config.template.yaml)             |
| `internal/`    | domain, delivery (handlers, mappers, middleware), repository, usecase, service, bootstrap |
| `migrations/`  | SQL-миграции PostgreSQL                                                                   |
| `pkg/`         | Общие пакеты                                                                              |
| `runner/`      | Сервис-раннер (llama.cpp, Ollama)                                                         |
| `scripts/`     | Скрипты сборки (deb, установщик Windows)                                                  |
| `tests/`       | Нагрузочные тесты                                                                         |

---

## Участие в разработке

Порядок внесения изменений и оформления Pull Request описан в [CONTRIBUTING.md](CONTRIBUTING.md).
