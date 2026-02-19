# Участие в разработке

Спасибо за интерес к проекту. Ниже - порядок внесения изменений и отправки Pull Request.

## Процесс

1. **Форк** - создайте форк репозитория в своём аккаунте.
2. **Клонирование** - клонируйте свой форк локально (подставьте имя своей учётки GitHub вместо `<имя-вашей-учётки>`):
   ```bash
   git clone https://github.com/<имя-вашей-учётки>/legion.git
   cd legion
   ```
3. **Удалённый upstream** (рекомендуется) - добавьте основной репозиторий и берите актуальный код из ветки `dev`:
   ```bash
   git remote add upstream https://github.com/magomedcoder/legion.git
   git fetch upstream
   git checkout -b my-feature upstream/dev
   ```
4. **Ветка** - все изменения делайте в отдельной ветке от `dev`, например: `feature/short-description` или `fix/issue-brief`.
5. **Коммиты** - делайте осмысленные коммиты с ясными сообщениями.
6. **Пуш** - отправьте ветку в свой форк:
   ```bash
   git push -u origin my-feature
   ```
7. **Pull Request** - откройте Pull Request **в ветку `dev`** основного репозитория (base: `dev`, head: ваша ветка из форка). Не отправляйте PR в `main`/`master`.

## Важно

- **Целевая ветка для Pull Request - `dev`.** Все Pull Request создаются с базой `dev`; в `main` попадают только после ревью и мержа из `dev`.
- Перед открытием Pull Request обновите свою ветку от актуальной `dev` (rebase или merge), чтобы уменьшить конфликты.

Спасибо за вклад!
