# MeuTreino+

MeuTreino+ e um aplicativo Flutter para acompanhamento de treinos de musculacao. O foco do projeto e oferecer uma experiencia simples para montar treinos, registrar series, acompanhar frequencia e visualizar evolucao sem excesso visual.

O app usa Firebase Authentication para login e Cloud Firestore para persistencia dos dados do usuario.

---

## Visao Geral

Com o app e possivel:

* Criar e organizar treinos personalizados.
* Montar uma sequencia semanal de treinos.
* Escolher dias esperados de treino.
* Registrar series, repeticoes, carga e descanso.
* Salvar historico completo das sessoes.
* Visualizar progresso e frequencia no calendario.
* Retomar treino em andamento ao reabrir o app.
* Voltar para a aba e para a tela principal em que o usuario estava.

---

## Funcionalidades

### Autenticacao

* Cadastro com e-mail e senha.
* Login com Firebase Authentication.
* Logout.
* Dados isolados por usuario autenticado.

### Biblioteca de Exercicios

* Lista de exercicios vinda do Firestore.
* Imagens locais para os exercicios.
* Organizacao por grupo muscular.
* Instrucoes basicas de execucao.
* Populacao inicial da biblioteca pelo proprio app.

As imagens ficam em:

```text
assets/exercises/
```

### Treinos

* Criar, editar e excluir treinos.
* Adicionar exercicios da biblioteca ao treino.
* Editar configuracoes de cada exercicio:
  * series
  * repeticoes
  * descanso
  * carga atual
  * observacoes
* Excluir exercicios do treino.
* Trocar exercicio por outro similar.
* Gerar treino automatico para montar uma base inicial.

### Treino Semanal e Sequencia ABC

O app permite configurar uma sequencia como:

```text
Treino A -> Treino B -> Treino C
```

Tambem e possivel:

* Editar o treino semanal pelo menu `Mais` da navbar.
* Definir os dias esperados de treino da semana.
* Ver o treino do dia na Home.
* Pular manualmente o treino atual pela Home sem registrar sessao concluida.

Regra da sequencia:

```text
O treino avanca automaticamente quando o usuario finaliza e salva o treino.
Se o usuario faltar, o treino nao e pulado sozinho.
Se necessario, o usuario pode avancar manualmente usando o botao "Pular treino".
```

### Treino em Andamento

Durante o treino, o app permite:

* Exibir foto grande do exercicio.
* Alternar entre os exercicios do treino.
* Mostrar serie atual.
* Registrar carga usada e repeticoes.
* Usar temporizador de descanso.
* Calcular volume parcial.
* Finalizar e salvar a sessao no Firestore.

Regras extras do fluxo:

* Exercicios de peso corporal nao exibem campo de carga no cadastro.
* Exercicios de peso corporal tambem ocultam a carga durante a sessao.
* O treino em andamento salva rascunho automaticamente.
* Ao abrir o app novamente, o treino em andamento pode ser retomado.

### Continuidade de Uso

Para reduzir perda de contexto ao sair do app:

* A ultima aba principal usada fica salva.
* A ultima tela principal de fluxos importantes pode ser restaurada.
* Se existir treino em andamento, ele pode ser reaberto automaticamente.

### Historico

Ao finalizar um treino, o app salva:

* treino realizado
* data de inicio
* data de finalizacao
* duracao
* series realizadas
* cargas usadas
* repeticoes feitas
* volume total
* total de series

O historico permite abrir a sessao e ver o detalhe de cada serie.

### Progresso

A tela de progresso mostra:

* total de treinos realizados
* volume total acumulado
* total de series
* media de volume por treino
* tendencia recente
* distribuicao por grupo muscular
* lista dos ultimos treinos

### Calendario de Frequencia

A Home possui calendario de frequencia com:

* dias concluidos
* dias perdidos dentro da meta semanal
* leitura por mes
* calculo com base nos dias esperados de treino

---

## Tecnologias Utilizadas

* Flutter
* Dart
* Firebase Authentication
* Cloud Firestore
* Riverpod
* Home Widget
* Table Calendar
* Intl

---

## Estrutura Resumida

```text
lib/
  app/
  core/
    navigation/
    utils/
    widgets/
  features/
    auth/
    exercises/
    exercise_stats/
    history/
    home/
    home_widgets/
    progress/
    workout_automation/
    workout_plan/
    workout_session/
    workouts/
```

---

## Servicos Firebase

### Firebase Authentication

Responsavel por login, cadastro e sessao do usuario.

### Cloud Firestore

Armazena:

* treinos
* exercicios da biblioteca
* exercicios dentro dos treinos
* plano semanal
* sessoes de treino
* series registradas
* dados de progresso

### Firebase Storage

Nao e utilizado na versao atual.

As imagens dos exercicios sao locais:

```text
assets/exercises/
```

---

## Modelo de Dados Resumido

```text
users/{userId}
users/{userId}/workouts/{workoutId}
users/{userId}/workouts/{workoutId}/exercises/{exerciseId}
users/{userId}/training_plan/main
users/{userId}/workout_sessions/{sessionId}
users/{userId}/workout_sessions/{sessionId}/sets/{setId}
exercise_library/{exerciseId}
```

Campos importantes do plano semanal:

```json
{
  "sequenceWorkoutIds": ["treinoA", "treinoB", "treinoC"],
  "currentWorkoutIndex": 0,
  "trainingWeekDays": [1, 2, 3, 4, 5]
}
```

Onde:

```text
1 = segunda
2 = terca
3 = quarta
4 = quinta
5 = sexta
6 = sabado
7 = domingo
```

---

## Instalacao

### 1. Clonar o projeto

```bash
git clone <url-do-repositorio>
cd meutreinoplus
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar Firebase

Instale o Firebase CLI:

```bash
npm install -g firebase-tools
```

Faca login:

```bash
firebase login
```

Instale o FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
```

Configure o projeto:

```bash
flutterfire configure
```

### 4. Rodar o app

```bash
flutter run
```

---

## Fluxo de Uso

### Primeiro uso

1. Criar conta.
2. Popular a biblioteca inicial de exercicios.
3. Criar treinos.
4. Adicionar exercicios aos treinos.
5. Configurar a sequencia semanal.
6. Definir os dias esperados de treino.
7. Iniciar treino pela Home ou pela tela do treino.

### Durante o treino

1. O app mostra o exercicio atual.
2. O usuario informa repeticoes e, quando fizer sentido, a carga usada.
3. O usuario conclui a serie.
4. O app atualiza o progresso parcial e o descanso.
5. Ao terminar o treino, o usuario salva a sessao.
6. O app registra o historico e avanca a sequencia semanal.

---

## Calculo de Volume

O volume de cada serie e calculado por:

```text
volume = carga x repeticoes
```

Exemplo:

```text
20 kg x 10 reps = 200 kg
```

O volume total do treino e a soma do volume de todas as series.

---

## Status Atual do Projeto

Funcionalidades ja implementadas:

* [x] Login com Firebase Authentication.
* [x] Cadastro de usuario.
* [x] Home com treino do dia.
* [x] Biblioteca de exercicios com imagens locais.
* [x] Criacao, edicao e exclusao de treinos.
* [x] Adicao, edicao e exclusao de exercicios do treino.
* [x] Troca de exercicio por similar.
* [x] Geracao de treino automatico.
* [x] Configuracao de sequencia ABC.
* [x] Edicao do treino semanal pela navbar.
* [x] Definicao de dias esperados de treino.
* [x] Botao para pular treino semanal sem registrar sessao concluida.
* [x] Temporizador de descanso.
* [x] Registro de series.
* [x] Salvamento de historico no Firestore.
* [x] Calculo de volume total.
* [x] Tela de historico com detalhe das series.
* [x] Tela de progresso.
* [x] Calendario de frequencia.
* [x] Rascunho de treino em andamento.
* [x] Retomada automatica de treino em andamento ao abrir o app.
* [x] Restauracao da aba e da ultima tela principal usada ao voltar para o app.
* [x] Tratamento de exercicios de peso corporal sem campo de carga.

---

## Melhorias Futuras

Melhorias recentes ja concluidas, antes tratadas como backlog:

* [x] Editar treino semanal pelo menu `Mais` da navbar.
* [x] Pular treino atual da sequencia sem registrar sessao.
* [x] Retomar treino em andamento ao iniciar o app.
* [x] Restaurar aba e tela recente ao voltar para o app.
* [x] Nao exibir campo de carga para exercicios de peso corporal.

Proximas melhorias sugeridas:

* [ ] Graficos de evolucao por exercicio.
* [ ] Evolucao de carga, repeticoes e volume por periodo.
* [ ] Metas semanais com percentual de adesao e streak.
* [ ] Lembretes e notificacoes de treino.
* [ ] Tela de perfil com preferencias do usuario.
* [ ] Medidas corporais e fotos de progresso.
* [ ] Backup e exportacao em PDF e CSV.
* [ ] Templates prontos de treino por objetivo.
* [ ] Reorganizacao de exercicios por drag and drop.
* [ ] Modo offline com fila de sincronizacao.
* [ ] Login com Google.
* [ ] Login com Apple.
* [ ] Filtros avancados no historico e na biblioteca.
* [ ] Recordes pessoais por exercicio.
* [ ] Superseries, dropsets, aquecimento e RPE/RIR.
* [ ] Duplicar treino e clonar semanas.
* [ ] Permissoes de administrador para gerenciar biblioteca global.

---

## Possiveis Problemas

### Imagem nao aparece

Verifique:

```text
1. A imagem existe dentro de assets/exercises/.
2. O nome do arquivo esta igual ao imageAsset salvo no Firestore.
3. O pubspec.yaml esta configurado corretamente.
4. O comando flutter pub get foi executado.
```

### Treino do dia nao aparece

Verifique:

```text
1. Existem treinos criados.
2. A sequencia semanal foi configurada.
3. O documento users/{uid}/training_plan/main existe.
4. Os IDs em sequenceWorkoutIds correspondem a treinos existentes.
```

### Treino em andamento nao voltou

Verifique:

```text
1. Havia um rascunho salvo antes de fechar o app.
2. O treino original ainda existe no Firestore.
3. O fluxo nao foi encerrado com salvamento final da sessao.
```

### Falta nao aparece no calendario

Verifique:

```text
1. Os dias esperados foram configurados.
2. O dia ja passou.
3. Nao existe sessao de treino salva para aquele dia.
```

---

## Autor

Desenvolvido por **Vinicius Pascoal**.

---

## Licenca

Projeto desenvolvido para estudo e evolucao pratica em Flutter com Firebase.
