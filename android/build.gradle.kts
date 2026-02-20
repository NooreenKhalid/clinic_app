import org.gradle.api.tasks.Delete
import org.gradle.kotlin.dsl.register

// Root project repositories
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Set a custom build directory outside default
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

// Subprojects custom build dirs
subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

// Ensure app module is evaluated first
subprojects {
    project.evaluationDependsOn(":app")
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}