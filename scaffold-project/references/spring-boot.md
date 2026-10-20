# Spring Boot

Read after the user picked Spring Boot (step 1 of `SKILL.md`). Spring Boot projects here are
applications — services and APIs — so the kind question is the language, and the branch policy is the
application variant.

## Interview

Asked in the same round as the shared questions. The shared name question asks for the **artifact
id** in kebab-case (e.g. `order-service`).

| Question | Default |
|---|---|
| "Java or Kotlin?" — skip if the request said | Java |
| "Gradle (Kotlin DSL) or Maven?" | Gradle (Kotlin DSL) |
| "Group id? (reverse domain, e.g. `com.acme`)" | none — ask; never invent `com.example` |
| "Java version?" | the default the Initializr metadata offers — but no newer than the JDK installed (`java -version`): the Gradle toolchain does not download one, so a newer version breaks the build |
| "Starters beyond `web`, `actuator` and `validation`? (e.g. `data-jpa`, `postgresql`, `security`, `flyway`)" | none |

The package name is `<group id>.<artifact id without dashes>` (`com.acme.orderservice`).

## Generate

Read the Initializr's live metadata first — it holds the current Boot version, the valid Java
versions and the dependency ids; never pass a value from memory:

```bash
tmp=$(mktemp -d)
curl -fsSL -H "Accept: application/vnd.initializr.v2.2+json" https://start.spring.io > "$tmp/initializr.json"
```

Check every starter the user named against `dependencies.values[].values[].id` in it. Then generate
into an empty temporary directory and extract there — a downloaded archive is unpacked in a directory
of its own, never straight into the repository:

```bash
curl -fsSL https://start.spring.io/starter.zip \
  -d type=gradle-project-kotlin -d language=java \
  -d groupId=<group id> -d artifactId=<artifact id> -d name=<artifact id> \
  -d description="<description>" -d packageName=<package name> \
  -d javaVersion=<java version> \
  -d dependencies=web,actuator,validation<,extras> \
  -o "$tmp/starter.zip"
mkdir "$tmp/starter" && unzip -q "$tmp/starter.zip" -d "$tmp/starter"
```

`type` is `gradle-project-kotlin`, `gradle-project` or `maven-project`; `language` is `java` or
`kotlin`. Move the extracted tree into the repository root, then delete `HELP.md` — the root README
replaces it — and the Initializr's `.gitattributes`, which `templates/.gitattributes` replaces in
step 6 (it already pins `*.bat` / `*.cmd` to CRLF and `gradlew` to LF).

## Shape

The Initializr writes `src/main/…` and `src/test/…`. Production code stays in `src/main/java` (or
`src/main/kotlin`) and `src/main/resources` — the Spring Boot plugins, IDEs and the Initializr itself
expect it, and it is already under `src/`. **Tests move to `tests/`:**

```bash
mkdir -p tests
mv src/test/java tests/java              # Kotlin: src/test/kotlin → tests/kotlin
if [ -d src/test/resources ]; then mv src/test/resources tests/resources; else mkdir -p tests/resources && touch tests/resources/.gitkeep; fi
rmdir src/test
```

and point the build at them.

**Gradle, Kotlin DSL** (`build.gradle.kts`):

```kotlin
sourceSets {
    test {
        java.setSrcDirs(listOf("tests/java"))
        resources.setSrcDirs(listOf("tests/resources"))
    }
}
```

For Kotlin, the Kotlin source set is configured instead of (or besides) `java`:

```kotlin
kotlin {
    sourceSets["test"].kotlin.setSrcDirs(listOf("tests/kotlin"))
}
sourceSets["test"].resources.setSrcDirs(listOf("tests/resources"))
```

**Maven** (`pom.xml`, inside `<build>`):

```xml
<testSourceDirectory>tests/java</testSourceDirectory>  <!-- tests/kotlin for Kotlin -->
<testResources>
  <testResource>
    <directory>tests/resources</directory>
  </testResource>
</testResources>
```

The Initializr's `…ApplicationTests` (`contextLoads`) is the one test that comes with the scaffold:
it proves the context starts with every starter wired, which is infrastructure, not a sample. Keep it,
rename the method to the naming rule — `givenAllStarters_whenTheContextStarts_thenItLoads` — and tag it
`@Tag("functional")`, since it starts the whole context.

Gradle: replace the generated `tasks.withType<Test> { useJUnitPlatform() }` block with one that
filters by tag when asked to:

```kotlin
tasks.withType<Test> {
    useJUnitPlatform {
        project.findProperty("includeTags")?.toString()?.let { includeTags(it) }
    }
}
```

Maven needs nothing: `-Dgroups=<tag>` filters out of the box.

The Initializr indents Java, Kotlin and Gradle files with **tabs**, Spring's own convention. Keep them,
and add to the generated `.editorconfig`, after the shared sections:

```ini
[*.{java,kt,kts}]
indent_style = tab
```

`gradlew` / `mvnw` must stay executable for Linux CI, and Windows checkouts (`core.filemode=false`)
drop the bit: stage them with it — `git add --chmod=+x gradlew` (or `mvnw`) — and say so in the
report.

Add the build's own output to the root `.gitignore` if the generated one doesn't already ignore it
(`build/` and `.gradle/`, or `target/`).

## README fill-ins

- **Requirements:** `- Java <version> or later`.
- **Usage:** `./gradlew bootRun` (or `./mvnw spring-boot:run`), and the actuator health URL
  `http://localhost:8080/actuator/health`.

## CONTRIBUTING fill-ins

- **Prerequisites:** `- A JDK <version> or later, e.g. [Eclipse Temurin](https://adoptium.net/)` — the
  Gradle / Maven wrapper in the repository brings the build tool itself.
- **Build:** `./gradlew build -x test` (or `./mvnw -DskipTests package`).
- **Testing:**

  ````markdown
  Tests live under `tests/` — `tests/java` for the code, `tests/resources` for their resources — and are written with
  JUnit 5. Every test is named with the Given / When / Then pattern
  (`givenSomeCondition_whenSomeAction_thenSomeOutput`) and tagged `@Tag("unit")` or `@Tag("functional")`, so the two
  kinds can be run separately:

  ```bash
  ./gradlew test                              # everything
  ./gradlew test -PincludeTags=unit           # unit tests only
  ./gradlew test -PincludeTags=functional     # functional tests only
  ```
  ````

  For Maven, the commands are `./mvnw test`, `./mvnw test -Dgroups=unit` and
  `./mvnw test -Dgroups=functional`.

## Verify

```bash
./gradlew build                                        # compiles, runs the context test from tests/java
./gradlew test --rerun
grep -ho 'tests="[0-9]*"' build/test-results/test/*.xml   # must print tests="1"
```

Gradle prints no test count, and when the source set did not move the test task is `NO-SOURCE` and
the build still succeeds — the XML results are the proof. Maven: `./mvnw verify`, and read the
Surefire summary for `Tests run: 1`. On Windows use `gradlew.bat`
/ `mvnw.cmd`. A run that reports zero tests is a **failure** here: it means the build is not reading
`tests/`.

## Report

- The Boot version and Java version the Initializr resolved, and the starters.
- The CI job names to require besides the branch policy, if the user adds a CI workflow later.
