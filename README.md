# MeuTreino+

**MeuTreino+** é um aplicativo Flutter para acompanhamento de progressão na academia. O app permite organizar treinos por dia, separar exercícios por sequência ABC, registrar cargas e repetições, controlar tempo de descanso, acompanhar histórico de treinos e visualizar a frequência em um calendário.

O objetivo do projeto é oferecer uma experiência simples e visual para quem deseja acompanhar sua evolução na musculação, com fotos dos exercícios, registro de séries e controle automático do próximo treino.

---

## Funcionalidades

### Autenticação

* Cadastro de usuário com e-mail e senha.
* Login com Firebase Authentication.
* Logout.
* Dados separados por usuário autenticado.

### Biblioteca de Exercícios

* Lista de exercícios cadastrados no Firestore.
* Exibição de imagem local para cada exercício.
* Organização por grupo muscular.
* Instruções básicas de execução.
* Popular biblioteca inicial diretamente pelo app.

As imagens dos exercícios ficam salvas localmente no projeto, dentro da pasta:

```text
assets/exercises/
```

Exemplo de imagem cadastrada no Firestore:

```json
{
  "name": "Supino reto com halteres",
  "muscleGroup": "Peito",
  "imageAsset": "assets/exercises/supino_reto_halteres.jpg",
  "instructions": "Deite no banco, mantenha os pés firmes no chão e empurre os halteres para cima controlando a descida."
}
```

### Treinos

* Criar treinos personalizados.
* Editar nome e descrição dos treinos.
* Excluir treinos.
* Adicionar exercícios da biblioteca a um treino.
* Editar configurações do exercício no treino:

  * Séries.
  * Repetições.
  * Tempo de descanso.
  * Carga atual.
  * Observações.
* Excluir exercícios de um treino.

Exemplo de organização:

```text
Treino A — Peito, Ombro e Tríceps
Treino B — Costas e Bíceps
Treino C — Pernas
```

### Sequência ABC

O app permite configurar uma sequência de treino, por exemplo:

```text
Treino A → Treino B → Treino C
```

O sistema mostra automaticamente o próximo treino do dia na Home.

A sequência funciona com a seguinte regra:

```text
O treino só avança quando o usuário finaliza e salva o treino.
Se o usuário faltar, o treino não é pulado.
```

Exemplo:

```text
Segunda: Treino A aparece.
Usuário não treina.
Terça: Treino A continua aparecendo.
Usuário treina e salva.
Quarta: Treino B aparece.
```

### Treino em Andamento

Durante o treino, o app permite:

* Exibir foto grande do exercício.
* Mostrar exercício atual.
* Mostrar série atual.
* Informar carga usada.
* Informar repetições realizadas.
* Concluir série.
* Usar temporizador de descanso.
* Calcular volume parcial do treino.
* Finalizar e salvar treino no Firestore.

### Histórico de Treinos

Ao finalizar um treino, o app salva:

* Treino realizado.
* Data de início.
* Data de finalização.
* Duração.
* Séries realizadas.
* Cargas usadas.
* Repetições feitas.
* Volume total.
* Total de séries.

O histórico permite consultar os treinos anteriores e visualizar os detalhes das séries feitas.

### Progresso

A tela de progresso mostra:

* Total de treinos realizados.
* Volume total acumulado.
* Total de séries realizadas.
* Volume médio por treino.
* Lista dos últimos treinos.

### Calendário de Frequência

A Home possui um calendário que indica a frequência do usuário:

* Dias em verde: usuário treinou.
* Dias em vermelho: usuário faltou em um dia esperado de treino.

Os dias esperados são definidos na configuração da sequência ABC.

Exemplo:

```text
Segunda a sexta selecionados como dias de treino.
Se o usuário treinar na segunda, o dia fica verde.
Se faltar na terça, o dia fica vermelho.
```

---

## Tecnologias Utilizadas

* Flutter
* Dart
* Firebase Authentication
* Cloud Firestore
* FlutterFire CLI
* Riverpod
* Table Calendar
* Intl
* UUID

---

## Serviços Firebase Utilizados

### Firebase Authentication

Usado para autenticação de usuários com e-mail e senha.

### Cloud Firestore

Usado para armazenar:

* Dados do usuário.
* Biblioteca de exercícios.
* Treinos.
* Exercícios dentro dos treinos.
* Sequência ABC.
* Histórico de treinos.
* Séries realizadas.
* Dados de progresso.

### Firebase Storage

Este projeto **não utiliza Firebase Storage na versão atual**.

As imagens dos exercícios são armazenadas localmente em:

```text
assets/exercises/
```

---

## Estrutura de Pastas

```text
lib/
  main.dart
  firebase_options.dart

  app/
    app_widget.dart
    app_theme.dart

  core/
    utils/
      date_key.dart
    widgets/
      exercise_image.dart
      rest_timer.dart

  features/
    auth/
      data/
        auth_service.dart
      presentation/
        auth_gate.dart
        login_page.dart
        register_page.dart

    home/
      presentation/
        home_page.dart
        widgets/
          attendance_calendar.dart

    exercises/
      data/
        exercise_library_service.dart
      models/
        exercise.dart
      presentation/
        exercise_library_page.dart
        select_exercise_page.dart

    workouts/
      data/
        workout_service.dart
      models/
        workout.dart
        workout_exercise.dart
      presentation/
        workouts_page.dart
        workout_detail_page.dart

    workout_plan/
      data/
        workout_plan_service.dart
      models/
        workout_plan.dart
      presentation/
        workout_plan_page.dart

    workout_session/
      data/
        workout_session_service.dart
      models/
        completed_set_input.dart
        performed_set.dart
        workout_session_summary.dart
      presentation/
        workout_session_page.dart

    history/
      presentation/
        history_page.dart
        history_detail_page.dart

    progress/
      presentation/
        progress_page.dart
```

---

## Estrutura de Assets

As imagens dos exercícios devem ficar em:

```text
assets/
  exercises/
    supino_reto_halteres.jpg
    supino_inclinado_halteres.jpg
    puxada_frente.jpg
    remada_baixa.jpg
    leg_press.jpg
    cadeira_extensora.jpg
    mesa_flexora.jpg
    triceps_corda.jpg
    rosca_direta.jpg
    elevacao_lateral.jpg
```

No `pubspec.yaml`, os assets devem estar configurados assim:

```yaml
flutter:
  uses-material-design: true

  assets:
    - assets/exercises/
```

---

## Modelo de Dados no Firestore

### Usuários

```text
users/{userId}
```

Exemplo:

```json
{
  "name": "Vinicius",
  "email": "vinicius@email.com",
  "createdAt": "timestamp"
}
```

---

### Biblioteca de Exercícios

```text
exercise_library/{exerciseId}
```

Exemplo:

```json
{
  "name": "Supino reto com halteres",
  "muscleGroup": "Peito",
  "imageAsset": "assets/exercises/supino_reto_halteres.jpg",
  "instructions": "Deite no banco, mantenha os pés firmes no chão e empurre os halteres para cima controlando a descida.",
  "createdAt": "timestamp"
}
```

---

### Treinos do Usuário

```text
users/{userId}/workouts/{workoutId}
```

Exemplo:

```json
{
  "name": "Treino A",
  "description": "Peito, ombro e tríceps",
  "weekDays": [],
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

---

### Exercícios Dentro do Treino

```text
users/{userId}/workouts/{workoutId}/exercises/{exerciseId}
```

Exemplo:

```json
{
  "exerciseLibraryId": "supino_reto_halteres",
  "name": "Supino reto com halteres",
  "muscleGroup": "Peito",
  "imageAsset": "assets/exercises/supino_reto_halteres.jpg",
  "order": 1,
  "sets": 3,
  "targetReps": "8-10",
  "restSeconds": 90,
  "currentWeight": 20,
  "notes": "",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

---

### Plano de Treino ABC

```text
users/{userId}/training_plan/main
```

Exemplo:

```json
{
  "sequenceWorkoutIds": [
    "idTreinoA",
    "idTreinoB",
    "idTreinoC"
  ],
  "currentWorkoutIndex": 0,
  "trainingWeekDays": [1, 2, 3, 4, 5],
  "updatedAt": "timestamp"
}
```

Onde:

```text
1 = segunda
2 = terça
3 = quarta
4 = quinta
5 = sexta
6 = sábado
7 = domingo
```

---

### Sessões de Treino

```text
users/{userId}/workout_sessions/{sessionId}
```

Exemplo:

```json
{
  "workoutId": "idTreinoA",
  "workoutName": "Treino A",
  "startedAt": "timestamp",
  "finishedAt": "timestamp",
  "workoutDateKey": "2026-06-18",
  "durationSeconds": 3600,
  "totalVolume": 8420,
  "totalSets": 18,
  "status": "finished",
  "createdAt": "timestamp"
}
```

---

### Séries Realizadas

```text
users/{userId}/workout_sessions/{sessionId}/sets/{setId}
```

Exemplo:

```json
{
  "workoutExerciseId": "idDoExercicioNoTreino",
  "exerciseLibraryId": "supino_reto_halteres",
  "exerciseName": "Supino reto com halteres",
  "muscleGroup": "Peito",
  "setNumber": 1,
  "weight": 20,
  "reps": 10,
  "volume": 200,
  "completedAt": "timestamp"
}
```

---

## Regras do Firestore

Durante o desenvolvimento, podem ser usadas regras simples para permitir que o usuário acesse apenas os próprios dados.

```js
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    match /users/{userId} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;

      match /{document=**} {
        allow read, write: if request.auth != null
                           && request.auth.uid == userId;
      }
    }

    match /exercise_library/{exerciseId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

Em uma versão final, a escrita em `exercise_library` deve ser limitada a administradores.

---

## Instalação do Projeto

### 1. Clonar o projeto

```bash
git clone <url-do-repositorio>
cd meutreinoplus
```

### 2. Instalar dependências

```bash
flutter pub get
```

### 3. Configurar Firebase

Instale o Firebase CLI:

```bash
npm install -g firebase-tools
```

Faça login:

```bash
firebase login
```

Instale o FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
```

Configure o Firebase no projeto:

```bash
flutterfire configure
```

Esse comando deve gerar o arquivo:

```text
lib/firebase_options.dart
```

### 4. Ativar Firebase Authentication

No Firebase Console:

```text
Build > Authentication > Get started > Sign-in method > Email/Password > Enable
```

### 5. Criar Cloud Firestore

No Firebase Console:

```text
Build > Firestore Database > Create database
```

Use modo de produção e depois configure as regras informadas neste README.

### 6. Adicionar imagens dos exercícios

Crie a pasta:

```text
assets/exercises/
```

Adicione as imagens usadas na biblioteca inicial.

Exemplo:

```text
assets/exercises/supino_reto_halteres.jpg
```

### 7. Rodar o app

```bash
flutter run
```

---

## Fluxo de Uso

### Primeiro uso

1. Criar conta.
2. Acessar a Home.
3. Abrir a Biblioteca de Exercícios.
4. Clicar para popular a biblioteca inicial.
5. Criar os treinos, por exemplo:

   * Treino A.
   * Treino B.
   * Treino C.
6. Adicionar exercícios a cada treino.
7. Configurar a sequência ABC.
8. Selecionar os dias esperados de treino.
9. Iniciar treino pela Home.

### Durante o treino

1. O app mostra o exercício atual.
2. O usuário informa carga e repetições.
3. O usuário conclui a série.
4. O app mostra o temporizador de descanso.
5. Ao terminar todos os exercícios, o usuário salva o treino.
6. O app salva o histórico e avança para o próximo treino da sequência.

---

## Cálculo de Volume

O volume de cada série é calculado por:

```text
volume = carga × repetições
```

Exemplo:

```text
20 kg × 10 reps = 200 kg
```

O volume total do treino é a soma do volume de todas as séries realizadas.

---

## Regra do Próximo Treino

O próximo treino é controlado pelo campo:

```text
currentWorkoutIndex
```

Exemplo:

```json
{
  "sequenceWorkoutIds": ["treinoA", "treinoB", "treinoC"],
  "currentWorkoutIndex": 0
}
```

Nesse caso, o treino atual é:

```text
sequenceWorkoutIds[0] = treinoA
```

Depois que o treino é finalizado, o app altera:

```json
{
  "currentWorkoutIndex": 1
}
```

Então o próximo treino passa a ser:

```text
sequenceWorkoutIds[1] = treinoB
```

Se o usuário faltar, o índice não muda.

---

## Status Atual do Projeto

Funcionalidades implementadas ou planejadas na estrutura atual:

* [x] Login com Firebase Authentication.
* [x] Cadastro de usuário.
* [x] Home.
* [x] Biblioteca de exercícios com imagens locais.
* [x] Criação de treinos.
* [x] Adição de exercícios ao treino.
* [x] Configuração de sequência ABC.
* [x] Exibição do treino do dia.
* [x] Temporizador de descanso.
* [x] Registro de séries.
* [x] Salvamento de histórico no Firestore.
* [x] Cálculo de volume total.
* [x] Tela de histórico.
* [x] Tela de progresso.
* [x] Calendário de frequência.
* [x] Edição e exclusão de treinos.
* [x] Edição e exclusão de exercícios do treino.

---

## Melhorias Futuras

* Adicionar gráficos de evolução por exercício.
* Mostrar evolução de carga por período.
* Criar metas semanais de treino.
* Criar lembretes de treino.
* Adicionar tela de perfil.
* Adicionar medidas corporais.
* Permitir backup/exportação em PDF.
* Adicionar templates prontos de treino.
* Permitir reorganizar exercícios por drag and drop.
* Criar modo offline aprimorado.
* Adicionar login com Google.
* Criar permissões de administrador para gerenciar biblioteca global.

---

## Possíveis Problemas

### Imagem não aparece

Verifique:

```text
1. A imagem existe dentro de assets/exercises/.
2. O nome do arquivo está igual ao imageAsset salvo no Firestore.
3. O pubspec.yaml está configurado corretamente.
4. O comando flutter pub get foi executado.
```

### Calendário não fica em português

Verifique se o `main.dart` possui:

```dart
await initializeDateFormatting('pt_BR', null);
```

E se o calendário possui:

```dart
locale: 'pt_BR'
```

### Treino do dia não aparece

Verifique:

```text
1. Existem treinos criados.
2. A sequência ABC foi configurada.
3. O documento users/{uid}/training_plan/main existe.
4. Os IDs em sequenceWorkoutIds correspondem a treinos existentes.
```

### Falta não aparece em vermelho

Verifique:

```text
1. Os dias esperados foram configurados.
2. O dia já passou.
3. Não existe sessão de treino salva para aquele dia.
```

---

## Autor

Desenvolvido por **Vinicius Pascoal**.

---

## Licença

Este projeto foi desenvolvido para fins de estudo e evolução prática em Flutter com Firebase.
