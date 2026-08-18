import org.gradle.api.tasks.Delete
import org.gradle.kotlin.dsl.register
import org.gradle.kotlin.dsl.configure
import com.android.build.api.dsl.LibraryExtension
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

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

// image_gallery_saver 2.0.3 predates the Android Gradle Plugin namespace
// requirement. Keep the existing ImageBB/gallery workflow intact while
// supplying the namespace declared by the plugin's Android manifest.
subprojects {
    plugins.withId("com.android.library") {
        if (name == "image_gallery_saver") {
            extensions.configure<LibraryExtension> {
                namespace = "com.example.imagegallerysaver"
            }
            tasks.withType<KotlinCompile>().configureEach {
                kotlinOptions.jvmTarget = "1.8"
            }
        }
    }
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
