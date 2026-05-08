// Top-level build file where you can add configuration options common to all sub-projects/modules.
plugins {
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.layout.buildDirectory.set(rootProject.projectDir.parentFile.resolve("build"))

subprojects {
    val projectDir = project.projectDir.canonicalPath
    val rootDir = rootProject.projectDir.canonicalPath
    if (projectDir.startsWith(rootDir)) {
        project.layout.buildDirectory.set(rootProject.layout.buildDirectory.dir(project.name))
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
