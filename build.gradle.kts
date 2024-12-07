@Suppress("DSL_SCOPE_VIOLATION")
plugins {
  base
  alias(libs.plugins.spotless)
  alias(libs.plugins.pkl)
}

pkl {
  evaluators {
    register("evalPkl") {
      projectDir.set(file("."))
      multipleFileOutputDir = layout.projectDirectory.dir("build/clusters/")
      sourceModules.set(fileTree(projectDir) { include("manifests/clusters/**/output.pkl") })
    }
  }
}

spotless {
  format("pkl") {
    target("**/*.pkl")
  }
}

tasks.check {
  dependsOn(tasks.named("evalPkl"))
}
