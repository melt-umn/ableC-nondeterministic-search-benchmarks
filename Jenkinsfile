#!groovy

library "github.com/melt-umn/jenkins-lib"

// This isn't a real extension, so we use a semi-custom approach

melt.setProperties(silverBase: true, ablecBase: true, silverAblecBase: true)

def extension_name = 'ableC-nondeterministic-search-benchmarks'
def extensions = [
  'ableC-nondeterministic-search',
  'ableC-closure',
  'ableC-refcount-closure',
  'ableC-string',
  'ableC-templating',
  'ableC-constructor',
  'ableC-vector',
  'ableC-algebraic-data-types'
]

melt.trynode(extension_name) {
  def newenv

  stage ("Checkout") {
    // We'll check it out underneath extensions/ just so we can re-use this code
    // It shouldn't hurt because newenv should specify where extensions and ablec_base can be found
    newenv = ablec.prepareWorkspace(extension_name, extensions, true)
  }

  stage ("Test") {
    withEnv(newenv) {
      dir("extensions/ableC-nondeterministic-search-benchmarks") {
        sh "make -j"
      }
    }
  }

  /* If we've gotten all this way with a successful build, don't take up disk space */
  sh "rm -rf generated/* || true"
}

